package com.lumino.api.task

import com.lumino.api.common.ApiResponse
import com.lumino.api.common.CurrentUser
import com.lumino.api.task.dto.CreateTaskRequest
import com.lumino.api.task.dto.UpdateTaskRequest
import com.lumino.api.user.User
import jakarta.validation.Valid
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.UUID

@RestController
@RequestMapping("/api/tasks")
class TaskController(private val taskService: TaskService) {

    @GetMapping
    fun getTasks(
        @CurrentUser user: User,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate
    ) = ApiResponse.ok(taskService.getTasksForDay(user, date))

    @PostMapping
    fun createTask(@CurrentUser user: User, @Valid @RequestBody request: CreateTaskRequest) =
        ApiResponse.ok(taskService.createTask(user, request))

    @PutMapping("/{id}")
    fun updateTask(
        @CurrentUser user: User,
        @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateTaskRequest
    ) = ApiResponse.ok(taskService.updateTask(user, id, request))

    @DeleteMapping("/{id}")
    fun deleteTask(@CurrentUser user: User, @PathVariable id: UUID): ApiResponse<Unit> {
        taskService.deleteTask(user, id)
        return ApiResponse.ok(Unit)
    }
}
