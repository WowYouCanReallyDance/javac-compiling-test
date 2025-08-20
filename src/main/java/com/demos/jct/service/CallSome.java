package com.demos.jct.service;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class CallSome {
    public String callMeNow(String name) {
        return name + "! Are you here?";
    }

    public void comparaTwoObjs() {
        var origin = "000,111,222,333,444";
        var result = "000,111,222,333,444";

        if (origin.length() == result.length()) {
            System.out.println(">>> Length of two row is same! JOB CONTINUE!!!");
        } else {
            System.out.println(">>> Length of two row is NOT same! JOB DONE!!!");
            return;
        }

        final var splitChar = ",";

        var originItems = origin.split(splitChar);
        var resultItems = result.split(splitChar);

        if (originItems.length == resultItems.length) {
            System.out.println(">>> Length of two row (originItems and resultItems) is same! JOB CONTINUE!!!");
        } else {
            System.out.println(">>> Length of two row (originItems and resultItems) is NOT same! JOB DONE!!!");
            return;
        }

        for (int i = 0; i < originItems.length; i++) {
            if (!originItems[i].equals(resultItems[i])) {
                System.out.println(
                        (">>> Difference of this two on index "
                                + i
                                + ": origin = "
                                + originItems[i]
                                + "\t\t"
                                + "result = "
                                + resultItems[i]));
            }
        }
    }

    enum Gender {
        MAN, WOMAN,;
    }

    record Person(String name, Integer age, Gender gender) {
    }

    public void testForSomeLang() {
        final Map<Person, String> map = new HashMap<>(3);
        map.put(new Person("Matt Long", 23, Gender.MAN), "RealHandsome!");
        map.put(new Person("Matt Long", 23, Gender.MAN), "RealHandsome!");
        map.put(new Person("Matt Long", 23, Gender.MAN), "RealHandsome!");
        System.out.println(map);
    }

    public void testForVirtualThread() {
        final String hr = "--------------------------------------------"
                + "----------------------------------------------------"
                + "----------------------------------------------------";
        try (var execSvc = Executors.newVirtualThreadPerTaskExecutor();) {
            IntStream
                    .range(0, 10)
                    .mapToObj(i -> execSvc.submit(() -> {
                        Thread nowTheThread = Thread.currentThread();
                        StringBuilder stringBuilder = new StringBuilder();

                        stringBuilder
                                .append(hr)
                                .append("\n")
                                .append("🧶 The ")
                                .append(i)
                                .append("st thread is a ")
                                .append(nowTheThread.isVirtual() ? "virtual " : "platform ")
                                .append("thread!\n")
                                .append("➡️ Look! Its class name is ")
                                .append(nowTheThread.getClass().getName())
                                .append(", and full stringify information is: ")
                                .append(nowTheThread);

                        System.out.println(stringBuilder);

                        try {
                            Thread.sleep(Duration.ofSeconds(5));
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }))
                    .collect(Collectors.toList())
                    .forEach(t -> {
                        try {
                            t.get();
                        } catch (InterruptedException | ExecutionException e) {
                            e.printStackTrace();
                        }
                    });

            System.out.println(hr);
        }
    }
}
