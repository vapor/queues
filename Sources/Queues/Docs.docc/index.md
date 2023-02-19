# ``Queues``

Queues is a pure Swift queuing system that allows you to offload task responsibility to a side worker.

Some of the tasks this package works well for:

* Sending emails outside of the main request thread
* Performing complex or long-running database operations
* Ensuring job integrity and resilience
* Speeding up response time by delaying non-critical processing
* Scheduling jobs to occur at a specific time