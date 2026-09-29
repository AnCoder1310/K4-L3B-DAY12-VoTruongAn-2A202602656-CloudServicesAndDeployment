# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng placeholder bên dưới bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Võ Trường An  Mã học viên: 2A202602656

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

Tình huống: Khi triển khai service lên cloud (như Railway hoặc Render) nhưng người cấu hình quên thêm biến môi trường `AGENT_API_KEY`. Nếu để giá trị mặc định là `"changeme"`, container vẫn chạy bình thường nhưng API bị lộ lỗ hổng bảo mật nghiêm trọng: bất kỳ ai đoán được giá trị mặc định đều có thể gọi API trái phép, làm cạn kiệt ngân sách LLM và lộ tài nguyên. Nhờ cơ chế fail fast (không có giá trị mặc định), ứng dụng văng lỗi `ValidationError` và crash ngay lúc khởi động, orchestrator báo deploy thất bại và buộc lập trình viên phải cung cấp secret hợp lệ trước khi service mở ra ngoài Internet.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

Dòng log JSON thu được:
```json
{"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T03:28:27.772565+00:00", "user_id": "sv01", "cost_usd": 0.0001}
```

Hai việc làm được:
1. Cho phép các hệ thống giám sát tập trung (Datadog, CloudWatch, Loki/Grafana) parse tự động cấu trúc dữ liệu để tổng hợp chỉ số (metrics) theo từng `user_id`, tính tổng chi phí `cost_usd` theo thời gian thực và tự động kích hoạt cảnh báo (alert) khi chi phí vượt ngưỡng.
2. Cho phép lọc (filter) và truy vấn nhanh theo trường dữ liệu (ví dụ: `level == 'error'` hoặc `user_id == 'sv01'`) dựa trên thời gian chuẩn ISO 8601 mà không lo log bị vỡ dòng khi chạy đa luồng hoặc đa tiến trình.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ~1020 MB |
| Multi-stage | ~185 MB |

Giải thích: Phần dung lượng chênh lệch (~835 MB) bao gồm hệ điều hành nền đầy đủ (Debian standard thay vì slim), các công cụ biên dịch (GCC, build-essential, header C), build cache của pip và các file trung gian. Bản multi-stage chỉ copy các thư viện đã compile sang runtime base slim nên giảm thiểu tối đa dung lượng thừa.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

Khi sửa một ký tự trong `app/main.py` rồi build lại:
- Các layer được dùng lại từ cache: Stage `builder` (do `requirements.txt` không đổi), layer base `python:3.11-slim`, lệnh `COPY --from=builder` và lệnh tạo `useradd`.
- Các layer phải chạy lại: Lệnh `COPY app ./app` (do checksum file `main.py` thay đổi) và các lệnh khai báo sau đó.
- Nếu đặt `COPY . .` lên trước `RUN pip install`: Bất cứ thay đổi nào trong source code cũng làm mất hiệu lực (cache bust) layer cache từ dòng đó trở đi, khiến Docker phải tải và cài đặt lại toàn bộ thư viện mỗi khi sửa code, làm chậm quá trình build.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

Chuỗi sự kiện:
1. Ứng dụng tồn tại lỗ hổng (như Remote Code Execution, command injection) cho phép kẻ tấn công thực thi mã shell trong container.
2. Nếu container chạy với user mặc định là `root` (UID 0), kẻ tấn công chiếm toàn quyền kiểm soát bên trong container.
3. Kẻ tấn công lợi dụng các lỗ hổng container breakout (lỗ hổng kernel Linux, mount nhầm docker.sock hoặc privileged flag) để thoát ra ngoài container.
4. Do UID 0 bên trong container ánh xạ trực tiếp tới UID 0 (root) trên máy host (nếu không bật user namespace), kẻ tấn công lập tức có quyền root toàn bộ máy chủ host.
Lệnh `USER appuser` cắt đứt chuỗi tấn công ngay từ bước 2: mã độc chỉ chạy dưới quyền của user thường không có đặc quyền (unprivileged user), không thể ghi vào các file hệ thống nhạy cảm và giảm thiểu triệt để nguy cơ leo thang đặc quyền ra máy host.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

Số request tối đa trong 2 giây liên tiếp: 20 request.
Giải thích:
Với cơ chế đếm theo phút cố định (fixed window reset tại giây 00):
- Ở giây thứ 59 của phút thứ N (ví dụ 10:00:59), người dùng gửi dồn dập 10 request (đạt kịch trần 10 request của phút N).
- Ngay sau 1 giây, khi đồng hồ bước sang giây 00 của phút thứ N+1 (ví dụ 10:01:00 hoặc 10:01:01), bộ đếm lượt gọi tự động reset về 0. Người dùng lập tức gửi tiếp 10 request mới trong quota của phút N+1.
Tổng cộng trong khoảng thời gian chỉ 2 giây (từ 10:00:59 đến 10:01:01), hệ thống đã phải nhận 20 request (gấp đôi tải thiết kế). Thuật toán sliding window 60s giải quyết triệt để lỗ hổng này vì nó luôn tính tổng số request trong cửa sổ trượt 60 giây thực tế tính từ thời điểm gọi.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

Điểm khác nhau cốt lõi:
- Rate limit kiểm soát tần suất request ngắn hạn (đo bằng số lượt gọi/phút) để chống nghẽn mạng và bảo vệ hạ tầng CPU/RAM của server.
- Cost guard kiểm soát tổng chi phí tài chính dài hạn (đo bằng số tiền USD tích lũy/tháng) phát sinh từ việc tiêu thụ token LLM của từng user.

Hai tình huống cụ thể:
1. Rate limit cho qua nhưng Cost guard chặn: User gọi rất thong thả, chỉ 1 request/phút (hoàn toàn dưới hạn mức 10 req/phút). Tuy nhiên user này đã tiêu hết $9.98 trong ngân sách tháng $10.0. Request hiện tại có prompt dài với chi phí ước tính $0.05 (đưa tổng chi tiêu lên $10.03 > $10.0). Rate limiter cho qua nhưng Cost guard phát hiện vượt ngân sách và trả về mã lỗi HTTP 402 (Payment Required).
2. Cost guard cho qua nhưng Rate limit chặn: Vào đầu tháng, user có số dư chi tiêu là $0.00 trên ngân sách $10.00. Nhưng user gửi dồn dập 15 request chỉ trong vòng 3 giây. Mặc dù tổng chi phí còn rất dồi dào, Rate limiter vẫn lập tức chặn từ request thứ 11 với mã lỗi HTTP 429 (Too Many Requests) để bảo vệ server khỏi bị tấn công DoS.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> *Câu trả lời của bạn*

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> *Câu trả lời của bạn*

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> *Câu trả lời của bạn*
