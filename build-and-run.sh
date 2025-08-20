#!/bin/bash

# 主函数: 封装所有构建和运行相关逻辑, 复用变量
function build_and_run() {
    # 定义颜色常量
    local GREEN="\033[32m"
    local RED="\033[31m"
    local RESET="\033[0m"

    # 定义全局复用变量(在所有内部函数中可见)
    local jdkbin="${1:-/Library/Java/JavaVirtualMachines/graalvm-jdk-21.0.8+12.1/Contents/Home/bin}"
    local src_dir="src/main/java"
    local classes_dir="target/classes"
    local runnable_dir="target/jct-runnable"
    local manifest_file="target/MANIFEST.MF"
    local manifest_content="Main-Class: com.demos.jct.Main"
    local javac_path="${jdkbin}/javac"
    local jar_path="${jdkbin}/jar"
    local java_path="${jdkbin}/java"
    local fat_jar_path="target/jct-runnable.jar"
    local GREEN="\033[32m"
    local RESET="\033[0m"

    # 1. 创建资源函数(内部复用)
    function create_resource() {
        local type="$1"
        local path="$2"

        if [ -z "$type" ] || [ -z "$path" ]; then
            echo -e "${RED}>>>>>> 错误: 请提供类型(file/dir)和路径作为参数${RESET}"
            return 1
        fi

        if [ "$type" != "file" ] && [ "$type" != "dir" ]; then
            echo -e "${RED}>>>>>> 错误: 类型必须是 'file'(文件)或 'dir'(目录)${RESET}"
            return 1
        fi

        if [ -e "$path" ]; then
            if [ "$type" = "file" ]; then
                echo -e "${GREEN}>>>>>> 文件 '$path' 已存在${RESET}"
            else
                echo -e "${GREEN}>>>>>> 目录 '$path' 已存在${RESET}"
            fi
        else
            if [ "$type" = "file" ]; then
                touch "$path" && echo -e "${GREEN}>>>>>> 文件 '$path' 创建成功${RESET}"
            else
                mkdir -p "$path" && echo -e "${GREEN}>>>>>> 目录 '$path' 创建成功${RESET}"
            fi
        fi
    }

    # 2. 预处理函数(复用上层变量)
    function prehandle() {
        # 创建目录
        create_resource "dir" "$classes_dir"
        create_resource "dir" "$runnable_dir"

        # 处理MANIFEST.MF
        if [ ! -e "$manifest_file" ]; then
            create_resource "file" "$manifest_file"
            printf "%s\n\n" "$manifest_content" >> "$manifest_file"
            echo -e "${GREEN}>>>>>> 已向 '$manifest_file' 写入内容: $manifest_content(含末尾空行)${RESET}"
        else
            echo -e "${GREEN}>>>>>> 文件 '$manifest_file' 已存在, 跳过写入${RESET}"
        fi
    }

    # 3. 编译函数(复用上层变量)
    function compile() {
        # 检查jdkbin参数
        if [ -z "$jdkbin" ]; then
            echo -e "${RED}>>>>>> 错误: 请传入jdkbin参数(指定JDK的bin目录)${RESET}"
            return 1
        fi

        # 检查javac可执行文件
        if [ ! -x "$javac_path" ]; then
            echo -e "${RED}>>>>>> 错误: 找不到可执行的javac, 路径: $javac_path${RESET}"
            echo -e "${RED}>>>>>> 请确认jdkbin参数是否指向正确的JDK bin目录${RESET}"
            return 1
        fi

        # 检查源文件目录
        if [ ! -d "$src_dir" ]; then
            echo -e "${RED}>>>>>> 错误: 源文件目录不存在: $src_dir${RESET}"
            return 1
        fi

        # 查找并编译Java文件
        echo -e "${GREEN}>>>>>> 开始编译Java文件, 源目录: $src_dir, 目标目录: $classes_dir${RESET}"
        find "$src_dir" -name "*.java" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}>>>>>> 警告: 源目录下未找到.java文件${RESET}"
            return 0
        fi

        # 执行编译
        "$javac_path" -d "$classes_dir" $(find "$src_dir" -name "*.java")
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}>>>>>> Java文件编译成功, class文件已输出到: $classes_dir${RESET}"
        else
            echo -e "${RED}>>>>>> 错误: Java文件编译失败${RESET}"
            return 1
        fi
    }

    # 4. 构建fat jar函数(复用变量和逻辑)
    function build_to_fat_jar() {
        # 检查jar命令是否存在
        if [ ! -x "$jar_path" ]; then
            echo -e "${RED}>>>>>> 错误: 找不到可执行的jar命令, 路径: $jar_path${RESET}"
            return 1
        fi

        # 检查目标目录是否存在
        if [ ! -d "$runnable_dir" ]; then
            echo -e "${RED}>>>>>> 错误: runnable目录不存在: $runnable_dir${RESET}"
            return 1
        fi

        # 检查class文件目录是否存在且非空
        if [ ! -d "$classes_dir" ] || [ -z "$(ls -A "$classes_dir")" ]; then
            echo -e "${RED}>>>>>> 错误: class文件目录不存在或为空: $classes_dir${RESET}"
            return 1
        fi

        # 复制class文件到runnable目录
        echo -e "${GREEN}>>>>>> 复制class文件到 $runnable_dir ...${RESET}"
        cp -R "$classes_dir"/* "$runnable_dir"/
        if [ $? -ne 0 ]; then
            echo -e "${RED}>>>>>> 错误: 复制class文件失败${RESET}"
            return 1
        fi

        # 打包fat jar
        echo -e "${GREEN}>>>>>> 开始打包fat jar: $fat_jar_path${RESET}"
        "$jar_path" -cvfm "$fat_jar_path" "$manifest_file" -C "$runnable_dir" .
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}>>>>>> fat jar打包成功: $fat_jar_path${RESET}"
        else
            echo -e "${RED}>>>>>> 错误: fat jar打包失败${RESET}"
            return 1
        fi
    }

    # 5. 运行fat jar函数
    function run_fat_jar() {
        # 检查java命令是否存在
        if [ ! -x "$java_path" ]; then
            echo -e "${RED}>>>>>> 错误: 找不到可执行的java命令, 路径: $java_path${RESET}"
            return 1
        fi

        # 检查fat jar是否存在
        if [ ! -f "$fat_jar_path" ]; then
            echo -e "${RED}>>>>>> 错误: fat jar文件不存在: $fat_jar_path${RESET}"
            return 1
        fi

        # 执行jar文件
        echo -e "${GREEN}>>>>>> 开始运行fat jar: $fat_jar_path${RESET}"
        echo -e "${GREEN}>>>>>> 执行命令: $java_path -jar $fat_jar_path${RESET}"
        "$java_path" -jar "$fat_jar_path"
        
        # 捕获运行结果
        local run_exit_code=$?
        if [ $run_exit_code -eq 0 ]; then
            echo -e "${GREEN}>>>>>> fat jar运行成功${RESET}"
        else
            echo -e "${RED}>>>>>> fat jar运行失败, 错误码: $run_exit_code${RESET}"
        fi
        return $run_exit_code
    }

    # 主流程执行: 预处理→编译→构建fat jar→运行fat jar
    echo -e "${GREEN}>>>>>> 开始执行完整构建并运行流程...${RESET}"
    prehandle && compile && build_to_fat_jar && run_fat_jar
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}>>>>>> 完整流程(构建+运行)已成功完成${RESET}"
    else
        echo -e "${RED}>>>>>> 流程执行失败, 错误码: $exit_code${RESET}"
    fi
    return $exit_code
}

build_and_run "$@"