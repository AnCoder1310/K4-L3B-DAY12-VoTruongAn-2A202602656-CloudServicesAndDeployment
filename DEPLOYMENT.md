# Thông Tin Deploy — Checkpoint 5

> Điền file này sau khi deploy xong. `pytest tests/test_cp5.py` đọc file này
> để tìm địa chỉ service của bạn và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị API key vào đây.**
> Repo này công khai — dán khóa vào là mất khóa.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Võ Trường An |
| Mã học viên | 2A202602656 |
| Repo | https://github.com/AnCoder1310/K4-L3B-DAY12-VoTruongAn-2A202602656-CloudServicesAndDeployment |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | https://k4-l3b-day12-votruongan-2a202602656.onrender.com |
| Platform | Render|
| Ngày deploy | 2026-09-29 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | platform tự gán |
| `AGENT_API_KEY` | ✅ | đặt trong dashboard, không nằm trong repo |
| `REDIS_URL` | ✅ | Render Key Value (day12-redis) |
| `RATE_LIMIT_PER_MINUTE` | ✅ | 10 |
| `MONTHLY_BUDGET_USD` | ✅ | 10.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

Thay `https://k4-l3b-day12-votruongan-2a202602656.onrender.com` bằng Public URL ở trên:

```bash
# 1. Liveness — mong đợi 200 {"status":"ok"}
curl -i https://k4-l3b-day12-votruongan-2a202602656.onrender.com/health

# 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
curl -i https://k4-l3b-day12-votruongan-2a202602656.onrender.com/ready

# 3. Không có API key — mong đợi 401
curl -i -X POST https://k4-l3b-day12-votruongan-2a202602656.onrender.com/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Hello"}'

# 4. Có API key — mong đợi 200 kèm câu trả lời
curl -i -X POST https://k4-l3b-day12-votruongan-2a202602656.onrender.com/ask \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AGENT_API_KEY" \
  -H "X-User-Id: sv-test" \
  -d '{"question":"Deploy là gì?"}'

# 5. Rate limit — gọi 15 lần, những lần cuối phải trả 429
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "%{http_code} " -X POST https://k4-l3b-day12-votruongan-2a202602656.onrender.com/ask \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $AGENT_API_KEY" \
    -H "X-User-Id: sv-test" \
    -d '{"question":"test"}'
done; echo
```

## Kết Quả Chạy Thật

Dán output của các lệnh trên vào đây:

```

1 

❯  curl -i https://k4-l3b-day12-votruongan-2a202602656.onrender.com/health
HTTP/2 200 
date: Tue, 29 Sep 2026 13:16:01 GMT
content-type: application/json
cf-cache-status: DYNAMIC
rndr-id: ef20bab2-28ba-404b
server: cloudflare
vary: Accept-Encoding
x-render-origin-server: uvicorn
cf-ray: a42b428e8b41dda0-HKG
alt-svc: h3=":443"; ma=86400

{"status":"ok","service":"day12-agent","version":"1.0.0"}%   


2

❯  curl -i https://k4-l3b-day12-votruongan-2a202602656.onrender.com/ready
HTTP/2 200 
date: Tue, 29 Sep 2026 13:32:55 GMT
content-type: application/json
cf-cache-status: DYNAMIC
rndr-id: ad6ae5c6-087e-4780
server: cloudflare
vary: Accept-Encoding
x-render-origin-server: uvicorn
cf-ray: a42b5b4bc8950651-HKG
alt-svc: h3=":443"; ma=86400

{"status":"ready","redis":true}%                             


3

❯  curl -i -X POST https://k4-l3b-day12-votruongan-2a202602656.onrender.com/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Hello"}'
HTTP/2 401 
date: Tue, 29 Sep 2026 13:37:28 GMT
content-type: application/json
cf-cache-status: DYNAMIC
rndr-id: 37007094-1346-404b
server: cloudflare
vary: Accept-Encoding
x-render-origin-server: uvicorn
cf-ray: a42b61f67bed04ef-HKG
alt-svc: h3=":443"; ma=86400

{"detail":"invalid or missing API key"}%  


4

❯  curl -i -X POST https://k4-l3b-day12-votruongan-2a202602656.onrender.com/ask \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AGENT_API_KEY" \
  -H "X-User-Id: sv-test" \
  -d '{"question":"Deploy là gì?"}'
HTTP/2 200 
date: Tue, 29 Sep 2026 13:40:41 GMT
content-type: application/json
cf-cache-status: DYNAMIC
rndr-id: a13c7543-ec5d-46c2
server: cloudflare
vary: Accept-Encoding
x-render-origin-server: uvicorn
cf-ray: a42b66ac28fccabc-HKG
alt-svc: h3=":443"; ma=86400

{"answer":"Câu hỏi hay. Deploy là gì thường được giải quyết bằng cách chuẩn hóa môi trường chạy: cùng một image chạy giống nhau ở laptop và trên cloud. (Mình đang nhớ 20 lượt trao đổi trước đó.)","user_id":"sv-test","history_length":20,"cost_usd":9.345e-05,"tokens":{"in":443,"out":45}}% 


5

❯  URL="https://k4-l3b-day12-votruongan-2a202602656.onrender.com"

for i in $(seq 1 15); do
  curl -s -o /dev/null -w "%{http_code} " \
    -X POST "$URL/ask" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $AGENT_API_KEY" \
    -H "X-User-Id: sv-test" \
    -d '{"question":"test"}'
done
echo
200 200 200 200 200 200 200 200 200 200 429 429 429 429 429 
```

## Ảnh Chụp Màn Hình

Đặt ảnh trong thư mục `screenshots/`:

- `screenshots/dashboard.png` — trang quản lý service trên platform
- `screenshots/health.png` — kết quả gọi `/health` từ trình duyệt hoặc curl

---
