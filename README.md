# BettyStores

A key/value store that supports key expiry. A design decision was to use the Registry module as a backing store. One of the reasons is that it has been designed to handle big loads. But there are some disadvantages of using it:

  1. A test fails in bucket_registry_test.exs: the reason being that we can't properly clean the Registry process once it was started in another test. So the backing store isn't cleaned in between tests. An attempt was made to force this by implementing `BucketStore.terminate`. But it is not a good solution.
  1. Also because of the implementation of the Registry module as a process, it would need to be started in the Application module. However, that hardwires the underlying implementation of the backing store in the app and is not what I wanted to express with the BettyStores behaviour.
  1. Outside of the tests, in order to write identical keys to different buckets, we need to encode a `{bucket, key}` as the key to store. Not very elegant as well.
  1. Another issue is the fact that the administration to keep track of key expiry is not optimal by using a sorted list of timestamps that indicate when keys need to expire.

Given these issues, it would be better to create another version that uses ETS tables to store the keys together with their expiry timestamps and values. However that would not solve the problem of losing data in case of a crash, for that we would need to add another backing store to disk (possibly using dets but it is not as performant as ets).

Note: one of the reasons I wanted to try the Registry module is because it can spread the load over multiple CPU cores. However, to distribute truly over different nodes, we could use remote Tasks using async/await quite easily as explained in the document [Distributed tasks and configuration](https://elixir-lang.org/getting-started/mix-otp/distributed-tasks-and-configuration.html).

However, in the case this was truly needed, I would definitely use mnesia since it can sync its tables over a cluster of nodes and guarantee data consistency. However, mnesia has a bit of a quirky interface. We could also use Redis, RabbitMQ (which uses mnesia for its data storage) or other NoSQL stores. I have used Riak KV but am not sure what is status is at the moment given that the company went bust, but I believe bet365.com wants to maintain it as an open source project.