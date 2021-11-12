import signal
import datetime
import sys
import os
from time import sleep
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

def print_to_stdout(*a):
    # Here a is the array holding the objects
    # passed as the argument of the function
    print(*a, file=sys.stdout)

class GracefulKiller:
    kill_now = False
    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def status(self):
        print_to_stdout(f"I am in {self.kill_now} status")

    def exit_gracefully(self, *_):
        self.kill_now = True

def requests_retry_session(
        retries=3,
        backoff_factor=0.3,
        status_forcelist=(500, 502, 504),
        session=None,
):
    session = session or requests.Session()
    retry = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session


def autoscale():
    processes_started = 0
    n_replicas = 1
    camunda_url = os.getenv('CAMUNDA_URL', "http://camunda-service:8080/engine-rest/history/process-instance/count")
    print_to_stdout(f"CAMUNDA_URL {camunda_url}")
    last_call = datetime.datetime.now() - datetime.timedelta(seconds=10)
    while not KILLER.kill_now:
        print_to_stdout("every xxx")
        try:
            response = requests_retry_session().get(
                camunda_url,
                params={'timestamp': format_date_camunda(last_call)},
                headers={'Content-Type': 'application/json'},
            )
        except requests.exceptions.HTTPError as errh:
            print_to_stdout(f"Http Error: {errh}")
        except requests.exceptions.ConnectionError as errc:
            print_to_stdout(f"Error Connecting: {errc}")
        except requests.exceptions.Timeout as errt:
            print_to_stdout(f"Timeout Error: {errt}")
        except requests.exceptions.RequestException as err:
            print_to_stdout(f"OOps: Something Else {err}")
        else:
            print('It eventually worked', response.status_code)
            if response.status_code == 200:
                print_to_stdout('Success!')
                json_response = response.json()
                print_to_stdout(f'Received response: {json_response}')

                processes_started_per_instance = processes_started / n_replicas
                if processes_started_per_instance >= 50 and n_replicas < 4:
                    print_to_stdout("⬆️ Add 1 replica to Camunda Engine deploymentt")
                elif processes_started_per_instance <= 20 and n_replicas > 1:
                    print_to_stdout("⬇️ Remove 1 replica from Camunda Engine deployment")
                else:
                    print_to_stdout("➖ Do nothing")
                last_call = datetime.datetime.now()
            else:
                print_to_stdout(f'HTTP error occurred: {response.reason} retry in 10')
        sleep(10)
    print_to_stdout("End of the program. I was killed gracefully :)")

def format_date_camunda(date_time: datetime.datetime) -> str:
    """
    Returns a date time string for a using in a REST API call to Camunda Engine
    + is NOT URL-escaped

    Args:
        date_time: datetime.datetime object to convert

    Returns:
        str: String in the yyyy-MM-ddTHH:mm:ss.SSSZ format

    Example:
        date_time: datetime.datetime(2021, 1, 31, 12, 34, 56, 789000,
            tzinfo=datetime.timezone(datetime.timedelta(seconds=3600), 'CEST'))
        returns: 2021-01-31T12:34:56.789+0100
    """
    date = date_time.astimezone().isoformat(sep='T', timespec='milliseconds')
    return ''.join(date.rsplit(':', 1))


def main():
    autoscale()


if __name__ == '__main__':
    KILLER = GracefulKiller()
    main()
