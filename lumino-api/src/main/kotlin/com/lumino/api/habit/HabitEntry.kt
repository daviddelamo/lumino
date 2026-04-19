package com.lumino.api.habit

import jakarta.persistence.*
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

@Entity
@Table(name = "habit_entries")
class HabitEntry(
    @Id val id: UUID = UUID.randomUUID(),
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "habit_id") val habit: Habit,
    val entryDate: LocalDate,
    @Column(columnDefinition = "numeric")
    var value: Double = 1.0,
    var note: String? = null,
    val loggedAt: Instant = Instant.now()
)
