package com.lumino.api

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class LuminoApiApplication

fun main(args: Array<String>) {
    runApplication<LuminoApiApplication>(*args)
}
