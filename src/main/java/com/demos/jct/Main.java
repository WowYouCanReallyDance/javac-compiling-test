package com.demos.jct;

import com.demos.jct.service.CallSome;

public class Main {
    public static void main(String[] args) {
        CallSome callSome = new CallSome();
        String called = callSome.callMeNow("GaGaLeLe");
        System.out.println(called);
        callSome.comparaTwoObjs();
        callSome.testForSomeLang();
        callSome.testForVirtualThread();
    }
}