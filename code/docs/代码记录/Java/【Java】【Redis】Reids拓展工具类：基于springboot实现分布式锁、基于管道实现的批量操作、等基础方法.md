---
title: 【Java】【Redis】Reids拓展工具类：基于springboot实现分布式锁、基于管道实现的批量操作、等基础方法
copyright: CC-BY-4.0
tags:
  - java
  - redis
---

## 一、简介

RedisExtUtil 是一个基于 Spring 和 RedisTemplate 的扩展工具类，旨在提供更便捷的 Redis 操作方法，包括基础的 Key-Value 操作、分布式锁以及批量操作。本篇博客将介绍该工具类的核心功能及其批量操作的使用方法。

## 二、前置准备

在使用 RedisExtUtil 工具类之前，需要确保以下准备工作：

### 1.Maven配置

```XML
<!-- 这里排除了lettuce 根据情况需不需要排除 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
    <exclusions>
        <exclusion>
            <groupId>io.lettuce</groupId>
            <artifactId>lettuce-core</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<!-- hutool -->
<depen<!-- 这里排除了lettuce 根据情况需不需要排除 -->dency>
    <groupId>cn.hutool</groupId>
    <artifactId>hutool-all</artifactId>
    <version>5.8.19</version>
</dependency>
```

### 2.Spring 配置

```java
@Bean
public <T> RedisTemplate<String, T> objectRedisTemplate(RedisConnectionFactory redisConnectionFactory) {
    RedisTemplate<String, T> template = new RedisTemplate<>();
    template.setConnectionFactory(redisConnectionFactory);
    template.setKeySerializer(new StringRedisSerializer());
    template.setValueSerializer(new FastJson2JsonRedisSerializer<>(Object.class));
    template.setHashKeySerializer(new StringRedisSerializer());
    template.setHashValueSerializer(new FastJson2JsonRedisSerializer<>(Object.class));
    template.afterPropertiesSet();
    return template;
}




public class FastJson2JsonRedisSerializer<T> implements RedisSerializer<T> {
    ...省略
}
```

### 3.Hutool 工具类依赖

这些依赖非关键代码，可以根据需求自行替换

```java
import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.CollectionUtil;
import cn.hutool.core.collection.ListUtil;
import cn.hutool.core.convert.Convert;
import cn.hutool.core.map.MapUtil;
import cn.hutool.core.util.ArrayUtil;
import cn.hutool.core.util.BooleanUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.digest.DigestUtil;
import cn.hutool.extra.spring.SpringUtil;
```

### 4.线程池配置

```java
@Bean
public ThreadPoolTaskExecutor taskExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    // 核心线程数 根据设备情况而定 这里只做演示
    executor.setCorePoolSize(10);
    // 最大线程数 根据设备情况而定 这里只做演示
    executor.setMaxPoolSize(100);
    // 队列大小 根据设备情况而定 这里只做演示
    executor.setQueueCapacity(9999);
    // 当最大池已满时，此策略保证不会丢失任务请求，但是可能会影响应用程序整体性能。 根据设备情况而定 这里只做演示
    executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
    executor.setThreadNamePrefix("异步线程-");
    executor.initialize();
    return executor;
}
```

### 5.Redis 服务

确保 Redis 服务已启动，并配置正确的连接参数。

## 三、代码实现

### 1.基础方法

#### 1.1.获取 RedisTemplate

```java
public static <T> RedisTemplate<String, T> getDefaultRedisTemplate() {
    return SpringUtil.getBean("objectRedisTemplate", RedisTemplate.class);
}
```

#### 1.2.Key 的生成规则

```java
public static String calcKey(String prefix, String key) {
    return StrUtil.isBlank(prefix) ? key : prefix + key;
}
```

#### 1.3.写入数据

```java
public static <T> void put(String prefix, String key, T value) {
    put(getDefaultRedisTemplate(), prefix, key, value);
}

public static <T> void put(RedisTemplate<String, T> redisTemplate, String prefix, String key, T value) {
    String toKey = calcKey(prefix, key);
    redisTemplate.boundValueOps(toKey).set(value);
}
```

#### 1.4.读取数据

```java
public static <T> T get(String prefix, String key, Class<T> clazz) {
    return get(getDefaultRedisTemplate(), prefix, key, clazz);
}

public static <T> T get(RedisTemplate<String, T> redisTemplate, String prefix, String key, Class<T> clazz) {
    String toKey = calcKey(prefix, key);
    return Convert.convert(clazz, redisTemplate.boundValueOps(toKey).get());
}
```

#### 1.5.删除数据

```java
public static void remove(String prefix, String... key) {
    remove(getDefaultRedisTemplate(), prefix, key);
}

public static <T> void remove(RedisTemplate<String, T> redisTemplate, String prefix, String... key) {
    List<String> keys = Arrays.stream(key).map(k -> calcKey(prefix, k)).collect(Collectors.toList());
    redisTemplate.delete(keys);
}
```

#### 1.6.获取所有 Key

```java
public static List<String> getAllKeys(String prefix) {
    return getAllKeys(getDefaultRedisTemplate(), prefix);
}

public static <T> List<String> getAllKeys(RedisTemplate<String, T> redisTemplate, String prefix) {
    Set<String> keys = redisTemplate.keys(prefix + "*");
    if (keys != null && !keys.isEmpty()) {
        return keys.stream().map(key -> StrUtil.removePrefix(key, prefix)).collect(Collectors.toList());
    }
    return new ArrayList<>();
}
```

### 2.分布式锁

#### 2.1.阻塞式锁

```java
public static void lock(String prefix, String lockKey, Long expiryTime) {
    lock(getDefaultRedisTemplate(), prefix, lockKey, expiryTime, null);
}
/**
 *
 * @param redisTemplate
 * @param prefix 前缀
 * @param lockKey 锁名
 * @param expiryTime 过期时间
 * @param maxWaitTime 最大等待时间
 */
public static void lock(RedisTemplate<String, Object> redisTemplate, String prefix, String lockKey, Long expiryTime, Long maxWaitTime) {
    long startTime = System.currentTimeMillis();
    expiryTime = expiryTime != null ? expiryTime : 20000L;
    maxWaitTime = maxWaitTime != null ? maxWaitTime : 60000L;
    String toKey = calcKey(prefix, lockKey);
    while (true) {
        Boolean success = redisTemplate.opsForValue().setIfAbsent(toKey, "locked", expiryTime, TimeUnit.MILLISECONDS);
        if (Boolean.TRUE.equals(success)) {
            return;
        }
        if (System.currentTimeMillis() - startTime >= maxWaitTime) {
            throw new RuntimeException("Failed to acquire lock within timeout.");
        }
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

#### 2.2.非阻塞式锁

```java
public static Boolean tryLock(String prefix, String lockKey, Long expiryTime) {
    return tryLock(getDefaultRedisTemplate(), prefix, lockKey, expiryTime);
}
/**
 *
 * @param redisTemplate
 * @param prefix 前缀
 * @param lockKey 锁名
 * @param expiryTime 过期时间
 */
public static Boolean tryLock(RedisTemplate<String, Object> redisTemplate, String prefix, String lockKey, Long expiryTime) {
    String toKey = calcKey(prefix, lockKey);
    expiryTime = expiryTime != null ? expiryTime : 20000L;
    return redisTemplate.opsForValue().setIfAbsent(toKey, "locked", expiryTime, TimeUnit.MILLISECONDS);
}
```

#### 2.3.释放锁

```java
public static void unlock(String prefix, String lockKey) {
    unlock(getDefaultRedisTemplate(), prefix, lockKey);
}

public static void unlock(RedisTemplate<String, Object> redisTemplate, String prefix, String lockKey) {
    String toKey = calcKey(prefix, lockKey);
    redisTemplate.delete(toKey);
}
```

### 3.批量操作

#### 3.1.批量写入

```java
/**
 * 批量写入Redis数据
 *
 * @param prefix 前缀
 * @param maps   数据
 * @param <T>    写入数据value类型
 */
public static <T> void writeBatch(String prefix, Map<String, T> maps) {
    writeBatch(getDefaultRedisTemplate(), prefix, maps);
}

/**
 * 批量写入Redis数据
 * 使用executePipelined使一批命令集打包成一个管道，一次性提交给Redis服务器
 *
 * @param redisTemplate redisTemplate Bean
 * @param prefix        前缀
 * @param maps          数据
 * @param <T>           写入数据value类型
 */
public static <T> void writeBatch(RedisTemplate<String, T> redisTemplate, String prefix, Map<String, T> maps) {
    RedisSerializer<String> serializer = redisTemplate.getStringSerializer();
    RedisSerializer<T> valueSerializer = (RedisSerializer<T>) redisTemplate.getValueSerializer();
    //注意：使用executePipelined使一批命令集打包成一个管道，一次性提交给Redis服务器（execute会等待前一个命令虽然是一个事务但是在有慢速命令情况会导致整个操作变慢）
    //手动控制connection.openPipeline() connection.closePipeline() 多线程下互相抢夺控制权会导致Redis Read Time Out
    redisTemplate.executePipelined(new RedisCallback<String>() {
        @Override
        public String doInRedis(RedisConnection redisConnection) throws DataAccessException {
            maps.forEach((toKey, toValue) -> {
                if (toKey == null) {
                    return;
                }
                byte[] keyByte = serializer.serialize(calcKey(prefix, toKey));
                byte[] valueByte = valueSerializer.serialize(toValue);

                if (keyByte != null && valueByte != null) {
                    redisConnection.set(keyByte, valueByte);
                }
            });
            return null;
        }
    });
}
```

#### 3.2.批量读取

```java
/**
 * 批量查询Redis数据
 *
 * @param prefix 前缀
 * @param keys   待查询Key的集合
 * @param <T>    查询数据value类型
 * @return
 */
public static <T> Map<String, T> readBatch(String prefix, List<String> keys) {
    return readBatch(getDefaultRedisTemplate(), prefix, keys);
}


/**
 * 批量查询Redis数据
 *
 * @param redisTemplate redisTemplate Bean
 * @param prefix        前缀
 * @param keys          待查询Key的集合
 * @param <T>           查询数据value类型
 * @return
 */
public static <T> Map<String, T> readBatch(RedisTemplate<String, T> redisTemplate, String prefix, List<String> keys) {
    Map<String, T> result = new HashMap<>();
    RedisSerializer<T> valueSerializer = (RedisSerializer<T>) redisTemplate.getValueSerializer();
    RedisSerializer<String> serializer = redisTemplate.getStringSerializer();
    //注意：使用executePipelined使一批命令集打包成一个管道，一次性提交给Redis服务器（execute会等待前一个命令虽然是一个事务但是在有慢速命令情况会导致整个操作变慢）
    //手动控制connection.openPipeline() connection.closePipeline() 多线程下互相抢夺控制权会导致Redis Read Time Out
    List<Object> redisResult = redisTemplate.executePipelined((RedisCallback<Map<String, T>>) connection -> {
        // 使用管道
        // 执行命令
        for (String key : keys) {
            connection.get(serializer.serialize(calcKey(prefix, key)));
        }
        // 获取命令的结果
        return null;
    }, valueSerializer);
    for (int i = 0; i < keys.size(); i++) {
        T value = (T) redisResult.get(i);
        result.put(keys.get(i), value);
    }
    return result;
}
```

#### 3.3.多任务批量写入

```java
/**
 * 批量写入Redis多线程任务
 *
 * @param prefix    前缀
 * @param maps      待写入Map
 * @param partition 以多少个Key查询分割线程查询
 * @param <T>       查询数据value类型
 * @return
 */
public static <T> void writeBatchTask(String prefix, Map<String, T> maps, Integer partition) {
    writeBatchTask(getDefaultRedisTemplate(), prefix, maps, partition);
}

/**
 * 批量写入Redis多线程任务
 *
 * @param redisTemplate redisTemplate Bean
 * @param prefix        前缀
 * @param maps          待写入Map
 * @param partition     以多少个Key查询分割线程查询
 * @param <T>           查询数据value类型
 * @return
 */
public static <T> void writeBatchTask(RedisTemplate<String, T> redisTemplate, String prefix, Map<String, T> maps, Integer partition) {
    if (maps.keySet().size() <= partition) {
        RedisExtUtil.writeBatch(redisTemplate, prefix, maps);
    } else {
        ThreadPoolTaskExecutor taskExecutor = SpringUtil.getBean("taskExecutor", ThreadPoolTaskExecutor.class);
        List<Future<String>> futureList = new ArrayList<>();
        List<Map<String, T>> partitionList = partitionByMap(maps, partition);
        for (int i = 0; i < partitionList.size(); i++) {
            Map<String, T> currMaps = partitionList.get(i);
            final int finalI = i;
            Future<String> future = taskExecutor.submit(new Callable<String>() {
                org.slf4j.Logger logger = LoggerFactory.getLogger(this.getClass());

                @Override
                public String call() {
                    Boolean isSuccess = true;
                    try {
                        RedisExtUtil.writeBatch(redisTemplate, prefix, currMaps);
                    } catch (Exception exception) {
                        exception.printStackTrace();
                        logger.error("缓存前缀:{} 批量缓存Redis出现错误 msg:{}", prefix, exception.getMessage());
                        isSuccess = false;
                    }
                    return StrUtil.format("缓存前缀:{} 缓存队列:{} 是否执行成功：{}", prefix, finalI, isSuccess);
                }
            });
            futureList.add(future);
        }
        if (CollUtil.isNotEmpty(futureList)) {
            for (Future<String> mapFuture : futureList) {
                try {
                    String msg = mapFuture.get();
                    RedisExtUtil.log.debug("{}", msg);
                } catch (Exception exception) {
                    exception.printStackTrace();
                }
            }
        }
    }
}
```

#### 3.4.批量读取

```java
/**
 * 批量查询Redis多线程任务
 *
 * @param prefix    前缀
 * @param keys      待查询key集合
 * @param partition 以多少个Key查询分割线程查询
 * @param <T>       查询数据value类型
 * @return
 */
public static <T> Map<String, T> readBatchTask(String prefix, List<String> keys, Integer partition) {
    return readBatchTask(getDefaultRedisTemplate(), prefix, keys, partition);
}

/**
 * 批量查询Redis多线程任务
 *
 * @param redisTemplate redisTemplate Bean
 * @param prefix        前缀
 * @param keys          待查询key集合
 * @param partition     以多少个Key查询分割线程查询
 * @param <T>           查询数据value类型
 * @return
 */
public static <T> Map<String, T> readBatchTask(RedisTemplate<String, T> redisTemplate, String prefix, List<String> keys, Integer partition) {
    Map<String, T> result = new HashMap<>();
    RedisExtUtil.log.info("Redis查询开始 前缀：{}", prefix);
    if (keys.size() <= partition) {
        result = RedisExtUtil.readBatch(redisTemplate, prefix, keys);
    } else {
        ThreadPoolTaskExecutor taskExecutor = SpringUtil.getBean("taskExecutor", ThreadPoolTaskExecutor.class);
        List<Future<Map<String, T>>> futureList = new ArrayList<>();
        List<List<String>> keysPartition = ListUtil.partition(keys, partition);
        for (int i = 0; i < keysPartition.size(); i++) {
            List<String> strings = keysPartition.get(i);
            final int finalI = i;
            Future<Map<String, T>> future = taskExecutor.submit(new Callable<Map<String, T>>() {
                org.slf4j.Logger logger = LoggerFactory.getLogger(this.getClass());

                @Override
                public Map<String, T> call() {
                    Map<String, T> stringTMap = new HashMap<>();
                    try {
                        stringTMap = RedisExtUtil.readBatch(redisTemplate, prefix, strings);
                    } catch (Exception exception) {
                        exception.printStackTrace();
                        logger.error("缓存前缀:{} 批量查询Redis出现错误 msg:{}", prefix, exception.getMessage());
                    }
                    RedisExtUtil.log.info("缓存前缀:{} 缓存队列:{} 是否执行成功：true", prefix, finalI);
                    return stringTMap;
                }
            });
            futureList.add(future);
        }
        if (CollUtil.isNotEmpty(futureList)) {
            for (Future<Map<String, T>> mapFuture : futureList) {
                try {
                    Map<String, T> res = mapFuture.get();
                    if (MapUtil.isNotEmpty(res)) {
                        result.putAll(res);
                    }
                } catch (Exception exception) {
                    exception.printStackTrace();
                }
            }
        }
    }
    RedisExtUtil.log.info("Redis查询结束 获取：{} 个 前缀：{}", result.size(), prefix);
    return result;
}
```

### 4.辅助操作

#### 4.1.是否匹配Key（忽略大小写）

```java
public static boolean containsAllByIgnoreCase(Collection<String> redisKeys, Collection<String> mapKeys) {
    if (CollUtil.isEmpty(redisKeys)) {
        return CollUtil.isEmpty(mapKeys);
    }

    if (CollUtil.isEmpty(mapKeys)) {
        return true;
    }

    if (redisKeys.size() < mapKeys.size()) {
        return false;
    }

    for (String str : mapKeys) {
        if (!redisKeys.contains(str.toUpperCase())) {
            return false;
        }
    }
    return true;
}
```

#### 4.2.切分Map

```java
public static <T> List<Map<String, T>> partitionByMap(Map<String, T> toMaps, int nums) {
    if (MapUtil.isEmpty(toMaps)) {
        return new ArrayList<>();
    }
    Set<String> keySet = toMaps.keySet();
    Iterator<String> iterator = keySet.iterator();
    int i = 1;
    List<Map<String, T>> total = new ArrayList<>();
    Map<String, T> map = new HashMap<>();
    while (iterator.hasNext()) {
        String next = iterator.next();
        map.put(next, toMaps.get(next));
        if (i == nums) {
            total.add(map);
            map = new HashMap<>();
            i = 0;
        }
        i++;
    }
    if (CollUtil.isNotEmpty(map)) {
        total.add(map);
    }
    return total;
}
```

## 三、演示操作

展示部分操作，锁操作

```java
public static void main(String[] args) {
    String prefix = "test_lock:RedisExpUtil:main:";
    String md5Params = DigestUtil.md5Hex("test");
    //方法锁命名  模块前缀_lock: + 类名: + 方法名: + 业务参数（建议转MD5）   例如：view_lock:RedisExpUtil:main:业务参数
    //阻断业务
    RedisExtUtil.lock(prefix,md5Params);
    try {
        //业务操作
    } catch (Exception exception) {
        exception.printStackTrace();
    } finally {
        RedisExtUtil.unlock(prefix,md5Params);
    }

    //非阻断业务
    if (RedisExtUtil.tryLock(prefix,md5Params)) {
        //业务操作
    } else {
        //请等待
    }
}
```

