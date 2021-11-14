import signal
import datetime
import sys
import os
from threading import Event
# from urllib.parse import urlencode, quote_plus
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
from kubernetes import client, config
from kubernetes.client.rest import ApiException

EXIT = Event()

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

class AutoScaler:
    def __init__(self):
        config.load_incluster_config()
        self.k8s = client.AppsV1Api()
        self.processes_started = 0
        self.n_replicas = 1
        self.camunda_url = os.getenv('CAMUNDA_URL',
                                     "http://camunda-service:8080/engine-rest/history/process-instance/count")

        # get number initial number of replicas
        try:
            api_response = self.k8s.read_namespaced_deployment(name="camunda-deployment",
                                                               namespace="default")
            self.n_replicas = api_response.status.replicas
            # print(api_response.status)
        except ApiException as exp:
            print(f"Exception when calling AppsV1Api->read_namespaced_deployment: {exp}")

        print(f"CAMUNDA_URL {self.camunda_url}")
        # self.first_call = datetime.datetime.now()
        self.last_call = datetime.datetime.now() - datetime.timedelta(seconds=10)

    @staticmethod
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


    def scale(self):
        try:
            # params = urlencode({'startedAfter':format_date_camunda(self.last_call)}, quote_via=quote_plus)
            url = f"{self.camunda_url}?startedAfter={format_date_camunda(self.last_call).replace('+','%2b')}"
            print(f"URL {url}")
            response = self.requests_retry_session().get(
                url,
                headers={'Content-Type': 'application/json'},
            )
        except requests.exceptions.HTTPError as errh:
            eprint(f"Http Error: {errh}")
        except requests.exceptions.ConnectionError as errc:
            eprint(f"Error Connecting: {errc}")
        except requests.exceptions.Timeout as errt:
            eprint(f"Timeout Error: {errt}")
        except requests.exceptions.RequestException as err:
            eprint(f"OOps: Something Else {err}")
        else:
            if response.status_code == 200:
                json_response = response.json()
                self.processes_started = json_response["count"]
                processes_started_per_instance = self.processes_started / self.n_replicas
                duration = datetime.datetime.now()-self.last_call
                print(f"Camunda Engine Replicas: {self.n_replicas}, "
                      f"Processes started in the last {duration.total_seconds()} "
                      f"seconds: {self.processes_started}, processes per instance: {processes_started_per_instance}")
                if processes_started_per_instance >= 50 and self.n_replicas < 4:
                    print("Action: Scaling up")
                    try:
                        self.k8s.patch_namespaced_deployment(name="camunda-deployment",
                                                             namespace="default",
                                                             body={"spec":{"replicas": self.n_replicas + 1}})
                        self.n_replicas += 1
                    except ApiException as exc:
                        print(f"Exception when calling AppsV1Api->patch_namespaced_deployment: {exc}")

                elif processes_started_per_instance <= 20 and self.n_replicas > 1:
                    print("Action: Scaling down")
                    try:
                        self.k8s.patch_namespaced_deployment(name="camunda-deployment",
                                                             namespace="default",
                                                             body={"spec":{"replicas": self.n_replicas - 1}})
                        self.n_replicas -= 1
                    except ApiException as exc:
                        print(f"Exception when calling AppsV1Api->patch_namespaced_deployment: {exc}")
                else:
                    print("Action: Not scaling")
                self.last_call = datetime.datetime.now()
            else:
                eprint(f'HTTP error occurred: {response.reason} retry in 10')

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
    autoscale = AutoScaler()
    while not EXIT.is_set():
        autoscale.scale()
        EXIT.wait(10)

    print("All done!")
    # perform any cleanup here

def quit_me(signo, _frame):
    print("Interrupted by %d, shutting down" % signo)
    EXIT.set()

if __name__ == '__main__':
    for sig in ('TERM', 'HUP', 'INT'):
        signal.signal(getattr(signal, 'SIG'+sig), quit_me)
    main()
