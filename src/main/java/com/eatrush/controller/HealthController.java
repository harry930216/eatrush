package com.eatrush.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/* 一個請求打 GET /api/health 進來、到你回 200 出去,中間 Spring 幫你做哪幾件、你要負責定義哪幾件? 
 * 瀏覽器/curl ──GET /api/health──▶ DispatcherServlet(總機)
  │
  ├─(1)component scan 時已把你的 class 登記成 bean、標記為 web 處理器
  ├─(2)查 handler mapping 表:GET + /api/health → 命中你的方法
  ├─ 呼叫你的方法 → 拿到回傳值
  └─(3)HttpMessageConverter 把回傳值寫進 response body,狀態碼預設 200
*/

@RestController
public class HealthController {
	@GetMapping("/api/health")
	public Map<String,String> checkHealth() {
		return Map.of("status","Good");
	}
}

// 這邊不用做判斷 回傳隨便的東西其實就代表有成功 沒特別設定 前端判斷200