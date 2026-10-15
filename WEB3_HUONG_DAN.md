> **LỊCH SỬ WEB3.** Đọc `WEB4_HUONG_DAN.md` cho bản hiện tại. Web4 dùng STA riêng khi nối Wi-Fi nhà, chỉ chuyển AP khi bạn chọn; sau PIN có bước L+R/intro. Nếu đã nạp đủ web3, chỉ cần cập nhật C3.

# ESP ConTL v1.1 / web3 — HDZ463

Bản sửa kết nối, khôi phục OLED và giao diện TV/điện thoại/tablet/máy tính. Ngày đóng gói: 07/10/2026.

> **Phải nạp lại cả C3 lẫn các bộ nhận bạn sử dụng:** `USB_Bridge_S3` và `Receiver_Test` đều có thay đổi. Không chỉ thay trang web hoặc chỉ nạp C3. Bộ web2 cũ được giữ riêng.
>
> Đã biên dịch 4 cấu hình và chạy kiểm thử phần mềm. **Chưa có board/OLED/TV thật để xác nhận hết lỗi mất kết nối hoặc màn hình đen.** Không có số đo độ ổn định sóng, FPS hay thời gian phục hồi phần cứng.

## 1. Nạp bằng Arduino IDE

Giải nén toàn bộ ZIP. Mở `.ino` trong đúng thư mục, giữ nguyên các file `.h`/`.cpp` cạnh nó; không trộn tab của bản cũ.

- Core **esp32 by Espressif Systems 3.0.7**.
- Thư viện: **NimBLE-Arduino 2.3.6**, **WebSockets 2.6.1** (Links2004), **Adafruit SSD1306 2.5.13**, **GFX 1.11.11**, **BusIO 1.17.4**.
- C3: `SmartController_C3/SmartController_C3.ino`, **ESP32C3 Dev Module**, **CDC On Boot Enabled**, **Huge APP**, flash đúng dung lượng board (cấu hình đã build là 4 MB).
- S3: `USB_Bridge_S3/USB_Bridge_S3.ino`, **ESP32S3 Dev Module**, **USB-OTG (TinyUSB)**, **CDC On Boot Enabled**, **Huge APP**. Khi dùng HID phải cắm **USB native**, không phải cổng USB-UART; cáp phải có dữ liệu.
- Receiver: `Receiver_Test/Receiver_Test.ino`, chọn đúng **ESP32 Dev Module** hoặc **ESP32C3 Dev Module**, Huge APP; C3 dùng native USB thì bật CDC.
- Mở Serial Monitor **115200**. C3 và receiver/S3 dùng hai cổng riêng để thu log hai đầu.

`WebAssets.h` đã nhúng sẵn trang web cuối cùng. **Không cần Node, Python hay upload SPIFFS để nạp và dùng firmware.** Hướng dẫn pinmap và cài đặt đầy đủ trong `README_VI.md`.

Pinmap giữ nguyên: CHRG4, STDBY5; J1 X0/Y1/SW10; J2 X3/Y2/SW6; L7/R20; OLED SDA8/SCL9, địa chỉ 0x3C, 128×64, xoay 180°.

## 2. Kết nối ESP Remote và USB via S3

### Luồng mới

1. Bộ nhận phát AP có tiền tố `espH_`. Trên C3 chọn ESP Remote hoặc USB via S3, quét và chọn bộ nhận.
2. C3 vào AP để trao đổi MAC/session bằng UDP.
3. Sau WELCOME, C3 **chủ động rời liên kết Wi-Fi STA nhưng vẫn giữ radio STA bật**, khóa kênh vừa học và xác nhận ESP-NOW bằng PONG. Dữ liệu không còn phụ thuộc vào việc duy trì association với AP. MAC chỉ giữ trong RAM.
4. Khi thấy `Center + J1/J2: arm`: **đưa cả hai cần về giữa, thả L/R, nhấn J1 SW hoặc J2 SW rồi thả hết nút**. Sau đó mới xuất điều khiển.
5. Nếu link yếu/mất: đầu ra về neutral, có thử bắt tay lại giới hạn **3 lần mỗi đợt mất link**. Khi nối lại vẫn cần thao tác xác nhận ở bước 4, **không tự phát lại nút đang giữ**. Hết số lần thử, dùng giao diện quét/chọn lại.

**Không nhầm việc STA đã rời AP với mất ESP-NOW.** Dòng `[LINK] detached STA; ESP-NOW-only ...` là luồng dự kiến. Trạng thái Wi-Fi “disconnected” hoặc mã STA disconnect lưu gần nhất có thể do lần rời AP chủ động; phải đối chiếu PONG/age/kênh và thời điểm, không kết luận lỗi chỉ từ mã đó.

### Các thay đổi ở hai đầu

- Heartbeat mỗi 250 ms, cửa sổ hữu hạn 8 probe; kiểm tra nonce, gói muộn/trùng và thời gian nhận. Ping quá 350 ms được tính mất; `Loss` không phải thống kê mọi gói CONTROL.
- Quá 600 ms không có PONG hợp lệ: C3 ngừng đầu ra điều khiển và yêu cầu rearm. Quá 2 giây: bắt đầu nhánh nối lại có giới hạn. Đây là ngưỡng lập lịch phần mềm, không phải số đo RF.
- Receiver/S3 chỉ khởi tạo lại radio sau **3 lần kiểm tra sức khỏe liên tiếp bị lỗi**, cách nhau khoảng 1 giây, tránh reset do một mẫu trạng thái thoáng qua.
- Nhận lại handshake phiên mới từ cùng MAC mà không phải chờ phiên cũ hết hạn.
- Trong backlog, lấy **CONTROL/NEUTRAL hợp lệ mới nhất**, không phát lại lần lượt các lệnh cũ. Vẫn kiểm tra MAC, session, thứ tự sequence và tuổi gói.
- **Giữ watchdog 300 ms của receiver/S3**, không tăng timeout để che mất gói. PING không làm mới watchdog điều khiển.
- Bộ nhận vẫn không in luồng joystick định kỳ trước CONTROL đầu tiên; thông báo boot/lỗi khởi tạo có thể xuất hiện.

Đây là tăng khả năng chịu lỗi và chẩn đoán, không chứng minh nguyên nhân ngắt trước đó chỉ do firmware. Nhiễu 2.4 GHz, nguồn, cáp và anten vẫn cần kiểm tra thực tế. ESP-NOW chưa mã hóa; không dùng bản demo cho tải nguy hiểm.

## 3. OLED đen nhưng tay cầm vẫn chạy

Đã bổ sung:

- Gửi lại cấu hình SSD1306 khoảng **5 giây/lần**, chỉ tại ranh giới frame; khôi phục charge pump/display-on và giữ lựa chọn invert. Không display-off trong lần refresh bình thường.
- Truyền từng đoạn **32 byte**, timeout I²C **8 ms**, lỗi thì có backoff **120 ms**.
- Sau 3 frame lỗi: hạ I²C xuống **100 kHz**, yêu cầu phục hồi bus có giới hạn tần suất tối thiểu 2 giây/lần.
- Phục hồi bus bằng SDA/SCL open-drain, tối đa 9 xung SCL + STOP, khởi động lại Wire và cấu hình panel.
- Kiểm thử mô phỏng cả NACK, refresh giữa frame, invert và millis wrap/uptime dài.

Các cơ chế này có thể giúp khi thanh ghi panel bị reset hoặc bus lỗi. **Không thể sửa nguồn OLED bị mất, mối hàn đứt, sai địa chỉ, panel hỏng hoặc dây gây nhiễu.** Không nối/tách dây khi đang cấp điện; kiểm tra nguồn theo thông số module, chung GND, dây SDA/SCL ngắn và pull-up không kéo GPIO ESP32 lên 5 V. GPIO9 còn là chân boot trên nhiều C3 SuperMini.

C3 có log `[SYS]` khoảng 10 giây/lần khi Serial kết nối: heap, khoảng cách vòng lặp lớn nhất, số frame/errors/recover/refresh OLED và clock I²C. `[OLED]` ghi lần phục hồi bus; `[BOOT]` giúp phân biệt reset C3 với panel đen trong khi C3 vẫn chạy. Nếu panel ACK bình thường nhưng không phát sáng, bộ đếm errors có thể vẫn bằng 0.

## 4. Web: chọn thiết bị, không bị chặn bởi fullscreen

### Mở web cùng C3

1. C3 → **Web Games** → chọn cách nối mạng **trên OLED mỗi lần**:
   - **C3 Wi-Fi/direct**: thiết bị nối `ConTL_Play_XXXX`, pass `ESPConTL11`, mở `http://192.168.4.1/`.
   - **Home Wi-Fi/router**: quét/chọn mạng, dùng **JOY1/J1 SW nhập mật khẩu ngay trên OLED**. Mật khẩu hiển thị và chỉ giữ trong RAM của phiên. Thiết bị mở LAN IP trên OLED. Không lưu router cho lần mở tiếp theo; có AP fallback khi nối router thất bại.
2. Trên web chọn **TV / Điện thoại / Máy tính / Tablet**.
3. **PIN hiện trên C3; nhập PIN đó trên web.** Nếu nhập bằng tay cầm, nhấn J2 trên C3 để cho phép bàn phím PIN trước, rồi dùng JOY1/J1 SW chọn số. Có thể nhập bằng remote/chạm/bàn phím của thiết bị.
4. **PIN đúng và phiên socket được xác nhận → vào thẳng thư viện.** Không còn trang bắt buộc fullscreen và không cần F11 để đi tiếp.
5. Nút **Toàn màn hình (tùy chọn)** chỉ yêu cầu trình duyệt hỗ trợ. API không có, bị từ chối hoặc Promise không trả kết quả đều không khóa giao diện; vẫn chơi trong cửa sổ.

TV dùng Ethernet hoặc Wi-Fi 5 GHz vẫn có thể mở C3 qua router nếu cùng LAN với C3 2.4 GHz. Tránh guest network/client isolation. Dùng URL **http://**, không ép HTTPS; firmware phục vụ HTTP80 và WS81.

### Chế độ theo thiết bị

| Thiết bị | Bố cục và nguồn điều khiển cục bộ tùy chọn |
|---|---|
| TV | Chữ/focus lớn; remote mũi tên điều hướng, OK chọn; khi chơi cục bộ OK = R, Back mở menu. Có hỗ trợ keyCode kiểu cũ, nhưng một số nút Back do hệ điều hành giữ lại. |
| Điện thoại | Co giãn theo màn hình; hai joystick cảm ứng độc lập + L/R/J1/J2, multi-touch và cancel/thả an toàn. Có thể xoay ngang. |
| Tablet | Bố cục rộng hơn, cùng hệ điều khiển cảm ứng hai joystick; có nhánh TouchEvent nếu thiếu PointerEvent. |
| Máy tính | Chuột/bàn phím điều hướng; chơi cục bộ WASD/mũi tên = J1, IJKL = J2, Shift = L, Space = R, Enter = J1 SW, Esc = menu. Pong: W/S vợt trái, ↑/↓ vợt phải. |

**C3 vẫn là nguồn mặc định khi chạy thật.** Muốn dùng nguồn cục bộ, chọn rõ nút chơi cục bộ trên màn PIN hoặc đổi nguồn trong Cài đặt. Chơi cục bộ không cần PIN vì không truy cập dữ liệu/cấu hình tay cầm. Bản preview không có ESP nên mặc định cục bộ.

Không tự chuyển sang bàn phím/cảm ứng khi C3 mất tín hiệu. Game dùng C3 sẽ dừng khi stream cũ quá 400 ms. Khi chơi cục bộ, gói C3 không bắn/điều hướng thay; khi chơi bằng C3, phím chơi cục bộ không bắn thay (Esc vẫn là phím mở menu). Blur/đổi tab xóa input và tạm dừng.

**Remote TV không thay thế được hai joystick cho toàn bộ 11 game.** Muốn chơi đầy đủ, đặc biệt Pong/hai cần, nên dùng C3. Trang vẫn cần JavaScript, Canvas và WebSocket cho kết nối C3. JS được build nhắm cú pháp Chrome58/Safari11 và có một số API fallback; **không cam kết mọi TV hoặc trình duyệt cũ đều chạy được**. Nếu còn lỗi, cần hãng/model TV và phiên bản trình duyệt.

Giữ thư viện 11 game, menu/controller navigation, pause/restart/xác nhận thoát và thao tác **giữ L+R+J1 SW+J2 SW 3 giây** về Home trên C3. Đã chặn nút R dùng gửi PIN bị giữ sang thư viện làm đổi bộ lọc ngoài ý muốn.

## 5. Checklist chạy trên phần cứng của bạn

Đây là **kế hoạch kiểm thử cần thực hiện**, không phải kết quả đã đo:

1. Nạp đủ các đầu. Mở log C3 và receiver/S3; chạy từng bộ nhận riêng ở khoảng 1–2 m, nguồn/cáp tốt, cần ở giữa.
2. Quét/chọn, xác nhận rearm. Thử đủ bốn trục và bốn nút; với S3 dùng một trình soạn thảo trống để kiểm tra HID, không thử trên cửa sổ chứa dữ liệu quan trọng.
3. Chạy mỗi bộ nhận ít nhất 30 phút. Ghi số lần đứt, `age`, `RSSI`, `txFail`, `qDrop`, heap và OLED errors; đổi khoảng cách/nguồn có kiểm soát để so sánh, không thay nhiều yếu tố cùng lúc.
4. Tắt C3 hoặc bộ nhận khi đang giữ một phím thử: receiver/S3 phải nhả đầu ra theo watchdog khi còn chạy. Bật lại: không được tự lặp phím; phải center + nhấn/thả J1/J2 mới điều khiển lại.
5. Nếu OLED đen: giữ nguyên trạng thái để thu log 20–30 giây, xem `[BOOT]` có lặp không, `[SYS]` có tiếp tục không và errors/recover có tăng không. Kiểm tra nguồn/dây khi đã tắt điện; không giả định refresh 5 giây chắc chắn sửa được.
6. TV: chọn TV → nhập PIN → thư viện; thử **không bật fullscreen**, từ chối fullscreen, remote OK/Back và điều khiển bằng C3. Thử thêm AP/router riêng.
7. Điện thoại/tablet: chọn đúng loại → chơi cục bộ → chạm đồng thời hai cần và nút, nhấc/ngắt touch, xoay màn, đổi tab rồi quay lại. PC: bàn phím hoặc C3 đúng nguồn đã chọn.
8. Thoát/vào Web Games vài lần: OLED phải hỏi mạng mỗi lần; router/pass cũ không được tự điền cho phiên sau. Kiểm tra lại BLE/USB/OLED games sau khi chuyển mode.

### Nếu còn lỗi, gửi gì?

- Model C3, S3, ESP32 receiver, OLED và TV/trình duyệt; nguồn/cáp đang dùng.
- Log **hai đầu**, từ lúc bật đến ít nhất 20 giây sau lỗi. Che SSID/IP/MAC nếu cần; không gửi mật khẩu hoặc PIN đang dùng.
- C3: `[BOOT]`, `[SCAN]`, `[LINK]`, `[SYS]`, `[OLED]`. Receiver/S3: `STOP`, `[RX-LINK]`, trạng thái USB.
- Lỗi xảy ra với bộ nhận nào, ở mode nào, khoảng cách bao nhiêu; khi màn đen điều khiển có tiếp tục không; có phải nhấn center+SW chưa.

## 6. Kiểm thử và sửa nguồn web

Kết quả và giới hạn từng phép thử: `verification/BUILD_AND_TEST.md`. Screenshot trong thư mục đó là **Chromium với demo/mock**, không phải ảnh TV/ESP thật.

Dành cho phát triển (không cần để nạp Arduino):

```sh
npm ci
npm run web
python3 tools/embed_web.py
bash tests/run_host_tests.sh
node tests/web_games_test.js
python3 tools/preview.py --port 5173
# Terminal khác, cần Python Playwright + Chromium:
python3 tests/browser_test.py
# Cần arduino-cli và các dependencies kể trên:
bash compile_all.sh
```

Sửa JS/CSS ở `web/src/`, không sửa trực tiếp bản sinh `web/app.js`, `games.js`, `style.css`. `web/index.html` và `web/compat.js` sửa trực tiếp. Sau đó build web và embed trước khi nạp C3. Preview `http://localhost:5173/?demo=1` chỉ chạy game cục bộ, không mô phỏng sóng/board.
