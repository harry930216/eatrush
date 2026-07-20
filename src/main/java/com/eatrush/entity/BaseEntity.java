package com.eatrush.entity;

import java.time.LocalDateTime;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;

@MappedSuperclass // 我不是表,但我的欄位算進子類的表
@EntityListeners(AuditingEntityListener.class) // 「存檔時派監聽器來填時間戳」
public abstract class BaseEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id; 
	// 「寫回」怎麼寫得進 private 欄位?
	//  反射(reflection) —— Java 執行期的後門,可以繞過 private 直接讀寫任何欄位。所有框架都靠它。

	@CreatedDate
	@Column(updatable = false)
	private LocalDateTime createdAt;
	
	
	public Long getId() {
		return id;
	}
	
	public LocalDateTime getCreatedAt() {
		return createdAt;
	}
}
