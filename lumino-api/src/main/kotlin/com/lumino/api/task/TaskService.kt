package com.lumino.api.task

import com.lumino.api.task.dto.*
import com.lumino.api.user.User
import org.springframework.security.access.AccessDeniedException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID

@Service
class TaskService(private val taskRepository: TaskRepository) {

    @Transactional(readOnly = true)
    fun getTasksForDay(user: User, date: LocalDate): List<TaskResponse> {
        val start = date.atStartOfDay().toInstant(ZoneOffset.UTC)
        val end = date.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC)
        return taskRepository.findByUserAndDate(user.id, start, end).map { TaskResponse.from(it) }
    }

    @Transactional
    fun createTask(user: User, request: CreateTaskRequest): TaskResponse {
        val task = taskRepository.save(
            Task(
                user = user, title = request.title, iconId = request.iconId,
                color = request.color, startAt = request.startAt, endAt = request.endAt,
                repeatRule = request.repeatRule, reminderOffsetMin = request.reminderOffsetMin,
                notes = request.notes
            )
        )
        return TaskResponse.from(task)
    }

    @Transactional
    fun updateTask(user: User, taskId: UUID, request: UpdateTaskRequest): TaskResponse {
        val task = taskRepository.findById(taskId).orElseThrow { NoSuchElementException("Task not found") }
        if (task.deletedAt != null) throw NoSuchElementException("Task not found")
        if (task.user.id != user.id) throw AccessDeniedException("Not your task")
        request.title?.let {
            if (it.isBlank()) throw IllegalArgumentException("title must not be blank")
            task.title = it
        }
        request.iconId?.let { task.iconId = it }
        request.color?.let { task.color = it }
        request.startAt?.let { task.startAt = it }
        request.endAt?.let { task.endAt = it }
        request.repeatRule?.let { task.repeatRule = it }
        request.reminderOffsetMin?.let { task.reminderOffsetMin = it }
        request.notes?.let { task.notes = it }
        request.completedAt?.let { task.completedAt = it }
        return TaskResponse.from(taskRepository.save(task))
    }

    @Transactional
    fun deleteTask(user: User, taskId: UUID) {
        val task = taskRepository.findById(taskId).orElseThrow { NoSuchElementException("Task not found") }
        if (task.deletedAt != null) throw NoSuchElementException("Task not found")
        if (task.user.id != user.id) throw AccessDeniedException("Not your task")
        task.deletedAt = Instant.now()
        taskRepository.save(task)
    }
}
