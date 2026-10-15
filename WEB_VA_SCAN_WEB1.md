> **LỊCH SỬ WEB1 — không dùng luồng web/router trong tài liệu này cho web2. Đọc `WEB_CONSOLE_WEB2.md`: chọn mạng/nhập mật khẩu bằng OLED, không lưu Wi-Fi, PIN nhập bằng controller, giao diện console mới. Discovery ở mục 5–6 vẫn giữ nguyên.**

# ESP ConTL v1.1-web1 — Wi-Fi Web Games & discovery
**Tác giả: HDZ463 · OS vẫn hiển thị ESP ConTL v1.1 · Bản cập nhật web1**

> **Nạp lại C3 và cả S3/Receiver_Test đang dùng.** Không áp dụng hướng dẫn “chỉ nạp C3” của bản UI1 cũ cho lần cập nhật này. Giữ nguyên GPIO, OLED xoay 180°, 11 game OLED, BLE NimBLE và hiệu ứng UI1.
>
> Đã biên dịch bốn cấu hình board và chạy kiểm thử trên máy tính. **Chưa thử trên C3/S3 thật**: không khẳng định lỗi scan thực tế đã hết, không công bố FPS/độ trễ đo trên phần cứng.

## 1. Nạp bằng Arduino IDE

Mở sketch trong thư mục tương ứng, giữ đầy đủ các file `.h/.cpp` đi kèm:

| Board | File mở | Thiết lập chính |
|---|---|---|
| C3 tay cầm | `SmartController_C3/SmartController_C3.ino` | ESP32C3 Dev Module; flash 4 MB; Huge APP; USB CDC On Boot Enabled |
| S3 cầu USB | `USB_Bridge_S3/USB_Bridge_S3.ino` | ESP32S3 Dev Module; Huge APP; USB-OTG (TinyUSB); CDC On Boot Enabled; dùng cổng USB native/cáp data |
| ESP32 nhận mẫu | `Receiver_Test/Receiver_Test.ino` | ESP32 Dev Module; Huge APP |
| C3 nhận mẫu | Cùng `Receiver_Test.ino` | ESP32C3 Dev Module; Huge APP; CDC Enabled |

Core: **esp32 by Espressif Systems 3.0.7**. Library Manager:
- Adafruit SSD1306 **2.5.13**, Adafruit GFX Library **1.11.11**, Adafruit BusIO **1.17.4**.
- NimBLE-Arduino **2.3.6** của h2zero.
- **MỚI: WebSockets 2.6.1 của Markus Sattler / Links2004**. Không nhầm với ArduinoWebsockets hoặc ESPAsyncWebServer.
- `WebServer`, WiFi, Preferences, USB và ESP-NOW có trong core.

`WebAssets.h` đã kèm sẵn, chứa trang web nén gzip trong firmware. **Không nạp LittleFS/SPIFFS, không cần Python hoặc Node để nạp bằng IDE.** Không trộn tab từ sketch cũ. Nếu sửa nguồn trong `web/`, chạy `python3 tools/embed_web.py` trước khi biên dịch lại C3.

## 2. Chơi bằng Wi-Fi trực tiếp — mặc định

1. Nạp C3, mở Home → **Web Games** bằng L/R và nhấn JOY1 SW hoặc JOY2 SW.
2. OLED hiển thị tên `ConTL_Play_XXXX`, IP và PIN 6 số. Thả hết nút để tay cầm sẵn sàng.
3. PC kết nối Wi-Fi **`ConTL_Play_XXXX`**, mật khẩu **`ESPConTL11`**. Chấp nhận thông báo “không có Internet”; không chuyển lại Wi-Fi khác.
4. Mở Chrome/Edge/Firefox mới tại **`http://192.168.4.1/`**. Gõ địa chỉ vào thanh địa chỉ, không tìm bằng Google; dùng **HTTP**, không phải HTTPS.
5. Bấm bánh răng → nhập **6 số trên OLED** → **Ghép tay cầm** → đóng cửa sổ.
6. Chọn game bằng chuột, hoặc **L/R** trên C3 để chuyển ô và **JOY1 SW/JOY2 SW** để mở game.
7. Trong game, hai joystick/nút gửi vào trình duyệt. Giữ **L + R + JOY1 SW + JOY2 SW**: dừng ngay; thả hết trước 3 giây để tiếp tục; giữ đủ **3 giây** để C3 về Home và tắt Web Games.

Không cần S3 hay Receiver_Test để chơi Web Games: **C3 → Wi-Fi → trình duyệt PC**. S3 chỉ cần cho chế độ xuất USB HID. Web Games không chạy đồng thời với BLE/ESP-NOW; đổi chế độ sẽ dừng kết nối trước đó.

## 3. Chơi qua router nhà + AP dự phòng

1. Lần đầu làm theo mục 2, ghép PIN trước.
2. Bánh răng → chọn **Kết nối Wi-Fi nhà + AP dự phòng**.
3. Nhập đúng SSID và mật khẩu mạng **2.4 GHz**, bấm **Lưu & áp dụng**. Mạng WPA2-Personal hoặc mạng mở được hỗ trợ; không có đăng nhập Enterprise/captive portal.
4. AP của C3 có thể đổi kênh theo router nên PC có thể rớt tạm thời. Sau khi nối thành công, OLED luân phiên hiện **AP IP / LAN IP**.
5. Cho PC vào cùng mạng LAN, mở **`http://<LAN IP trên OLED>/`**; ghép lại PIN tại địa chỉ mới nếu được yêu cầu (token trình duyệt gắn theo địa chỉ).
6. Nếu không nối router được trong **15 giây**, C3 quay về AP dự phòng. Mở lại AP IP hiển thị trên OLED. Mạng đã lưu được thử lại lần sau khi vào Web Games; hoặc lưu lại cấu hình để thử ngay.

C3 lưu lựa chọn chế độ, SSID và mật khẩu router trong Preferences riêng `contl_web`. Chọn **AP trực tiếp** để lần mở sau không thử router; **Quên mạng đã lưu** xóa SSID/mật khẩu trên C3. **Reset settings trên OLED chỉ reset cấu hình tay cầm/UI, không xóa router; dùng Quên mạng đã lưu để xóa Wi-Fi.** Mật khẩu trống với SSID không đổi sẽ giữ mật khẩu cũ; muốn chuyển cùng SSID sang mạng mở, quên mạng rồi nhập lại.

- PC được nối Ethernet hoặc Wi-Fi 5 GHz cũng được, **miễn cùng LAN với C3** và router không chặn thiết bị liên lạc nội bộ. C3 chỉ kết nối 2.4 GHz.
- Không dùng guest Wi-Fi có client isolation. Cho phép kết nối TCP **80 và 81**; không mở các cổng này ra Internet.
- Nếu LAN của router là `192.168.4.x`, AP dự phòng chuyển sang **`10.42.0.1`**; luôn ưu tiên IP thực tế trên OLED. Xử lý này dành cho xung đột phổ biến `/24`, không tự giải quyết mọi cấu hình subnet/VPN khác; mạng đặc biệt nên dùng AP trực tiếp.
- IP router cấp có thể thay đổi sau reboot. Không cần sửa MAC trong code, không cần mDNS.

## 4. 11 game màu trên trình duyệt

Các game cùng thể loại với bộ OLED, được viết lại cho Canvas 800×450; không phải phát hình OLED lên PC. Game/đồ họa chạy trên PC, C3 phục vụ file web và gửi joystick/nút qua WebSocket. Không cần Internet/CDN/ROM/tài nguyên thương mại.

| Game | Điều khiển chính trên C3 |
|---|---|
| Maze Munch | JOY1 đi trong mê cung |
| Star Defenders | JOY1 trái/phải, R bắn |
| Pocket Platform | JOY1 đi/cúi, L chạy/bắn, R nhảy |
| Falling Blocks | JOY1 ngang/rơi, L/R xoay, JOY1 SW thả nhanh |
| Tiny Flap | R hoặc JOY1 SW vỗ cánh |
| Duo Pong | JOY1 Y vợt trái, JOY2 Y vợt phải; hai người dùng hai cần trên cùng C3 |
| Twin Arena | JOY1 đi, JOY2 ngắm/bắn |
| Vector Storm | JOY1 đi, JOY2 ngắm/bắn, R dùng bom |
| Micro Racer | JOY1 rẽ, R ga, L phanh/lùi |
| Garden Snake | JOY1 đổi hướng |
| Mini Tanks | JOY1 đi bốn hướng, R bắn |

Có chơi lại, tạm dừng, toàn màn hình, âm thanh tùy chọn, game gần đây và kỷ lục lưu **trên trình duyệt hiện tại**, không trên C3. Kỷ lục theo AP IP và LAN IP có thể khác nhau. Hai trình duyệt kết nối cùng C3 sẽ nhận cùng đầu vào nhưng chạy hai phiên game độc lập, không phải multiplayer đồng bộ qua mạng.

- Chu kỳ gửi mục tiêu **25 ms / 40 Hz**; mô phỏng browser dùng bước **1/60 giây**. Đây là cấu hình phần mềm, **không phải số đo độ trễ/FPS thực tế**.
- Mất WebSocket hoặc không có gói mới quá **400 ms**: game tự dừng. Chuyển tab/mất focus cũng tạm dừng; nhấn Tiếp tục khi quay lại.
- Mục “Độ trễ WebSocket” đo vòng đi-về của ping ứng dụng, không phải tổng độ trễ joystick → hình ảnh.
- Web game dùng trục đã calibration/invert và nút L/R/SW trực tiếp, không dùng bảng gán phím HID của USB/BLE.
- Có thể chủ động chọn **Bàn phím máy tính** để chơi không cần C3. Không tự chuyển sang bàn phím khi tay cầm rớt mạng.

### Bản xem thử trên PC

Chạy `python3 tools/preview.py`, mở `http://127.0.0.1:5173/`. Hoặc mở `web/index.html` trực tiếp. Bản này hiện nhãn **BẢN XEM THỬ · PC**, không giả vờ đang kết nối ESP và khóa cấu hình Wi-Fi.

WASD/mũi tên = JOY1; IJKL = JOY2; Shift = L; Space = R; Enter = JOY1 SW; Esc = tạm dừng. Riêng Pong: W/S vợt trái, ↑/↓ vợt phải. Live preview đi kèm cũng là **bàn phím PC**, không phải bằng chứng thử sóng ESP32.

## 5. Những thay đổi nhằm khắc phục scan không thấy thiết bị

### Phía C3
- Dừng ESP-NOW/UDP và scan cũ, tắt tự reconnect, chờ radio ổn định **450 ms** trước khi quét.
- Pass 1: quét chủ động **kênh 6**, thời gian tối đa 450 ms/kênh.
- Pass 2: quét chủ động toàn dải, tối đa 350 ms/kênh, kể cả đã tìm được receiver ở pass 1.
- Nếu vẫn không có `espH_`: thêm pass 3 thụ động toàn dải, 500 ms/kênh.
- Không quét blocking trong vòng lặp UI; có timeout riêng 12 giây mỗi pass và khoảng nghỉ 350 ms.
- Khôi phục cờ SCANNING tồn dư của **Arduino-ESP32 3.0.7** sau khi đã dừng scan và đợi. Trong core này, `scanDelete()` không xóa cờ SCANNING, còn nhánh `scanComplete()` có thể trả RUNNING trước khi xét timeout. Đây là nhánh phòng lỗi sau hủy/timeout, **không khẳng định là nguyên nhân trên board của bạn**. Adapter dùng API protected của core đã chốt; nâng core phải rà lại/biên dịch lại.
- Gộp theo **BSSID**, không gộp chỉ theo tên; tối đa **24** receiver, ưu tiên RSSI mạnh. Kết nối đúng BSSID/kênh; thử join/handshake tối đa 2 lượt.
- Serial C3 in trạng thái từng pass, tên AP, kênh/RSSI, tổng AP và số `espH_`.

### Phía S3 và Receiver_Test
- AP-only, không có STA tự reconnect router kéo lệch kênh receiver.
- AP **hiện SSID**, kênh 6, beacon 100 ms, Wi-Fi sleep off, chuẩn b/g/n.
- Bắt tay trả **MAC SoftAP của receiver**, ESP-NOW peer dùng `WIFI_IF_AP` ở receiver; C3 vẫn dùng STA MAC / `WIFI_IF_STA`. MAC lấy lúc chạy, chỉ lưu RAM, **không hardcode/lưu peer vĩnh viễn**.
- Kiểm tra mode/kênh mỗi 3 giây; khi sai thì neutral đầu ra và khởi tạo lại AP + ESP-NOW + UDP. Nếu chưa phục hồi, thử lại đợt kiểm tra sau. Không tự tiếp tục phiên điều khiển cũ; C3 phải quét/chọn lại.
- Receiver_Test vẫn **im lặng khi chỉ chờ kết nối/ping**, chỉ in dữ liệu khi có CONTROL, một lần STOP khi vừa dừng, hoặc báo lỗi khởi tạo. Serial im lặng không đồng nghĩa AP chưa chạy.

## 6. Nếu nạp mới mà vẫn không thấy S3/receiver

Làm theo thứ tự, không chỉ bấm Rescan liên tục:

1. Nạp **cả hai đầu** từ cùng bộ này. Cấp nguồn ổn định, đặt cách nhau khoảng 0.5–2 m; chờ receiver khởi động trước khi scan.
2. Dùng điện thoại mở danh sách Wi-Fi, kiểm tra **`espH_USB-S3`** hoặc **`espH_TestReceiver`** có hiện không. Không cần kết nối điện thoại vào AP này.
3. Mở Serial Monitor **C3, 115200**, vào ESP Remote/USB via S3 rồi chờ hết các pass. OLED khi danh sách trống có số AP đã thấy; Rescan nằm trong danh sách.
4. Phân loại kết quả:

| Kết quả | Nên kiểm tra |
|---|---|
| Điện thoại cũng không thấy `espH_` | Firmware receiver/board chọn đúng, nguồn/reset/brownout, anten, lỗi khởi tạo receiver; không phải lỗi lọc danh sách trên C3 |
| Điện thoại thấy, C3 `AP:0` | Radio/nguồn/anten C3; log lỗi từng pass; thử gần hơn và thử AP 2.4 GHz khác |
| C3 thấy nhiều AP nhưng `espH:0` | Đúng tên và chữ hoa/thường `espH_`, khoảng cách, receiver có phát AP ổn định không, các dòng SSID trong log |
| Có `espH_` nhưng Join/handshake thất bại | Mật khẩu hai đầu, đã nạp lại receiver chưa, kênh/BSSID, receiver đang có controller khác giữ phiên |
| ESP-NOW sẵn sàng nhưng USB không điều khiển PC | Đây là nhánh khác: kiểm tra cáp USB native, TinyUSB và MNT/RDY/RX/K/M trong hướng dẫn fix1 |

Nếu còn lỗi, gửi **toàn bộ log `[SCAN]` trên C3**, dòng `[BOOT] reset=...`, model C3/S3, và cho biết điện thoại có thấy AP không. Log chứa tên Wi-Fi xung quanh; che các SSID riêng tư trước khi chia sẻ. Nếu receiver in `ERROR: receiver init failed`, gửi thêm dòng này.

## 7. Bảo mật và giới hạn

- AP dùng mật khẩu demo cố định `ESPConTL11`. Có PIN OLED đổi mỗi lần vào Web Games, token ngẫu nhiên 128-bit, giới hạn thử PIN sai và tối đa 2 phiên WebSocket. Token tạm lưu sessionStorage; không đưa PIN/mật khẩu vào `/api/status` hoặc log.
- Sửa Wi-Fi yêu cầu token và kiểm tra Origin. Tuy nhiên đây là **HTTP/WS không TLS**, mật khẩu router lưu NVS thông thường **không mã hóa**, không chống người có quyền đọc flash/chặn bắt lưu lượng trên mạng tin cậy đã bị xâm nhập.
- Chỉ dùng trên mạng riêng tin cậy. Không port-forward, không dùng làm dịch vụ công khai. Có thể dùng AP trực tiếp để khỏi lưu mật khẩu router.
- ESP-NOW/UDP giữ mức bảo mật demo của bản trước: không mã hóa ESP-NOW, trao đổi MAC không phải xác thực mật mã. Không dùng bản demo cho tải/máy có thể gây nguy hiểm.

## 8. Đã kiểm tra gì?

Xem `verification/BUILD_AND_TEST.md` và log đi kèm: bốn cấu hình firmware build PASS; host C++ sanitizer PASS; game web 330.000 bước mô phỏng; Chromium mở/chơi/pause/restart cả 11 game, layout PC/mobile và kiểm thử transport giả lập. **Chưa kiểm chứng RF, AP/router thật, đo heap khi chạy lâu, BLE/USB/nguồn hoặc tốc độ trên board thật.**

Checklist sau nạp: scan 10 lần có receiver → chọn/thoát/quét lại → USB/BLE như trước → AP chơi 10 phút → tắt/mở router → thử sai password để về AP → giữ 4 nút thoát → vào lại Web Games PIN đổi → lặp chuyển BLE/Web/Remote và kiểm tra reset/heap.
