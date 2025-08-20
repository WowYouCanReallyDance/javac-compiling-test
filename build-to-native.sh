#!/bin/bash

# 顶层函数：封装所有构建原生镜像的逻辑
function build_to_native() {
    # 定义颜色常量
    local GREEN="\033[32m"
    local RED="\033[31m"
    local RESET="\033[0m"
    
    # 定义路径变量
    local graalbin="${1:-/Library/Java/JavaVirtualMachines/graalvm-jdk-21.0.8+12.1/Contents/Home/bin}"
    local jar_file="target/jct-runnable.jar"
    local native_image_path="${graalbin}/native-image"
    local native_executable="target/jct-native"
    
    # 1. 检查GraalVM的bin目录
    function check_graalvm() {
        echo -e "${GREEN}>>>>>> 检查GraalVM目录: $graalbin${RESET}"
        
        # 检查目录是否存在
        if [ ! -d "$graalbin" ]; then
            echo -e "${RED}>>>>>> 错误: GraalVM目录不存在 - $graalbin${RESET}"
            return 1
        fi
        
        # 检查native-image命令是否存在
        if [ ! -x "$native_image_path" ]; then
            echo -e "${RED}>>>>>> 错误: 未在指定目录找到native-image命令，可能不是GraalVM的bin目录${RESET}"
            return 1
        fi
        
        # 检查java版本是否包含GraalVM
        local java_path="${graalbin}/java"
        if [ -x "$java_path" ]; then
            local java_version=$("$java_path" -version 2>&1 | grep -i "graalvm")
            if [ -z "$java_version" ]; then
                echo -e "${RED}>>>>>> 错误: 指定的Java不是GraalVM${RESET}"
                return 1
            fi
        else
            echo -e "${RED}>>>>>> 错误: 在指定目录未找到java命令${RESET}"
            return 1
        fi
        
        echo -e "${GREEN}>>>>>> GraalVM目录检查通过${RESET}"
        return 0
    }
    
    # 2. 检查JAR文件是否存在
    function check_jar_file() {
        echo -e "${GREEN}>>>>>> 检查JAR文件: $jar_file${RESET}"
        
        if [ ! -f "$jar_file" ]; then
            echo -e "${RED}>>>>>> 错误: JAR文件不存在 - $jar_file${RESET}"
            echo -e "${RED}>>>>>> 请先执行build-and-run.sh生成JAR文件${RESET}"
            return 1
        fi
        
        echo -e "${GREEN}>>>>>> JAR文件检查通过${RESET}"
        return 0
    }
    
    # 3. 使用native-image构建原生镜像
    function build_native_image() {
        echo -e "${GREEN}>>>>>> 开始构建原生镜像...${RESET}"
        echo -e "${GREEN}>>>>>> 执行命令: $native_image_path -jar $jar_file $native_executable${RESET}"
        
        "$native_image_path" -jar "$jar_file" "$native_executable"
        local exit_code=$?
        
        if [ $exit_code -ne 0 ]; then
            echo -e "${RED}>>>>>> 错误: 原生镜像构建失败，错误码: $exit_code${RESET}"
            return $exit_code
        fi
        
        echo -e "${GREEN}>>>>>> 原生镜像构建成功${RESET}"
        return 0
    }
    
    # 4. 运行原生可执行文件
    function run_native_executable() {
        echo -e "${GREEN}>>>>>> 检查原生可执行文件: $native_executable${RESET}"
        
        if [ ! -x "$native_executable" ]; then
            echo -e "${RED}>>>>>> 错误: 原生可执行文件不存在或不可执行 - $native_executable${RESET}"
            return 1
        fi
        
        echo -e "${GREEN}>>>>>> 开始运行原生可执行文件...${RESET}"
        echo -e "${GREEN}>>>>>> 执行命令: $native_executable${RESET}"
        "$native_executable"
        
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}>>>>>> 原生可执行文件运行成功${RESET}"
        else
            echo -e "${RED}>>>>>> 错误: 原生可执行文件运行失败，错误码: $exit_code${RESET}"
            return $exit_code
        fi
        
        return 0
    }
    
    # 主流程
    echo -e "${GREEN}>>>>>> 开始执行原生镜像构建流程...${RESET}"
    check_graalvm && check_jar_file && build_native_image && run_native_executable
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}>>>>>> 原生镜像构建和运行流程已成功完成${RESET}"
    else
        echo -e "${RED}>>>>>> 原生镜像流程执行失败，错误码: $exit_code${RESET}"
    fi
    
    return $exit_code
}

# 执行顶层函数，可传入GraalVM的bin目录作为参数
build_to_native "$@"
