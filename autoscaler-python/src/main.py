import signal
import datetime
import sys
import os
from threading import Event
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
from kubernetes import client, config
from kubernetes.client.rest import ApiException

# capture SIG events to stop pod when terminating
EXIT = Event()

# quick stderr function print
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

class AutoScaler:
    def __init__(self):

        # load k8s cluster config
        config.load_incluster_config()
        self.k8s = client.AppsV1Api()
        self.delta = 10
        self.n_replicas = 1
        self.camunda_url = os.getenv('CAMUNDA_URL',
                                     "http://camunda-service:8080/engine-rest/history/process-instance/count")

        self.deployment_to_scale = os.getenv('K8S_DEPLOYMENT', "camunda-deployment")
        self.deployment_namespace = os.getenv('K8S_NAMESPACE', "default")

        # get initial number of replicas
        try:
            api_response = self.k8s.read_namespaced_deployment(name=self.deployment_to_scale,
                                                               namespace=self.deployment_namespace)
            self.n_replicas = api_response.status.replicas

        except ApiException as exp:
            eprint(f"Exception when calling AppsV1Api->read_namespaced_deployment: {exp}")

        # initialize last_call to be N seconds ago
        self.last_call = datetime.datetime.now() - datetime.timedelta(seconds=self.delta)

    # GET calls with backoff and retry mechanism
    @staticmethod
    def requests_retry_session(
            retries=3,
            backoff_factor=0.3,
            status_forcelist=(500, 502, 504),
            session=None,
    ):
        """
        Returns request session capable of retrying and backoff logic

        Args:
            retries: Number of times to retry retrieving URL
            backoff_factor: How long to sleep between failed requests
                            {backoff factor} * (2 ** ({number of total retries} - 1))
            status_forcelist: the HTTP response codes to retry on
            session=None,

        Returns:
            session: session to perform the requests

        """

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
        """
        Auto scales the configured deployment based on reported load from external URL
        """

        # get process load in the last N seconds or the amount of seconds since last fail
        try:
            response = self.requests_retry_session().get(
                self.camunda_url,
                params={'startedAfter': format_date_camunda(self.last_call)},
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
                processes_started = json_response["count"]
                processes_started_per_instance = processes_started / self.n_replicas
                duration = datetime.datetime.now()-self.last_call

                # Scaling logic

                print(f"Camunda Engine Replicas: {self.n_replicas}, "
                      f"Processes started in the last {duration.total_seconds()} "
                      f"seconds: {processes_started}, processes per instance: {processes_started_per_instance}")
                if processes_started_per_instance >= 50 and self.n_replicas < 4:
                    print("Action: Scaling up")
                    try:
                        self.k8s.patch_namespaced_deployment(name=self.deployment_to_scale,
                                                             namespace=self.deployment_namespace,
                                                             body={"spec":{"replicas": self.n_replicas + 1}})
                        self.n_replicas += 1
                    except ApiException as exc:
                        eprint(f"Exception when calling AppsV1Api->patch_namespaced_deployment: {exc}")

                elif processes_started_per_instance <= 20 and self.n_replicas > 1:
                    print("Action: Scaling down")
                    try:
                        self.k8s.patch_namespaced_deployment(name=self.deployment_to_scale,
                                                             namespace=self.deployment_namespace,
                                                             body={"spec":{"replicas": self.n_replicas - 1}})
                        self.n_replicas -= 1
                    except ApiException as exc:
                        eprint(f"Exception when calling AppsV1Api->patch_namespaced_deployment: {exc}")
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

    try:
        autoscale.delta = int(os.getenv('DELTA', "10"))
    except ValueError:
        autoscale.delta = 10 # the default value in seconds

    while not EXIT.is_set():
        autoscale.scale()
        # adds the ability to exit while waiting sleep() keeps it blocked for SIGs
        EXIT.wait(autoscale.delta)

    print("All done!")

def quit_me(signo, _frame):
    print("Interrupted by %d, shutting down" % signo)
    EXIT.set()

if __name__ == '__main__':
    for sig in ('TERM', 'HUP', 'INT'):
        signal.signal(getattr(signal, 'SIG'+sig), quit_me)
    main()
