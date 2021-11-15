# Follow-up questions for the task

## How long did it take you to solve the exercise? Please be honest, we evaluate your answer to this question based on your experience.

6 hours

## Which additional steps would you take in order to make this code production ready? Why?

- would **scale up directly** to the required number of replicas for the ammount of incoming requests. Now, it scales up +-1 replica every N seconds depending on the reported load. In a real world scenario, I would benchmark the camunda-deployment to see how many requests can handle per replica and then scale directly to the correct number of replicas
- wait for the **replicas to be successfully** deployed before considering the deployment "scaled"
- add tests to the Python code
- add readinessProbe to the autoscaler

## Which step took most of the time? Why?

I did the setup, logic and python code in about 2h. Most of the extra time was consumed with RBAC and debugging. By mistake I reused the "camunda" label app name for the autoscaler-deployment, resulting in half of the requests towards http://camunda-service:8080 being routed to the autoscaler and failing, camunda-process-starter was trying to scale and was not able because of many requests going to the wrong pod (autoscaler-deployment).

## Do you have any feedback for us? (Any mistakes you've found in the challenge, something was not working with your setup, you've lost a lot of time with something avoidable etc.)

I enjoyed the challenge. Would love to have a way to easily adress questions about the "blackbox" parts of the challenge.