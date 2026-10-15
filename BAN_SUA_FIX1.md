> **Bản hiện tại: web2. Xem `WEB_CONSOLE_WEB2.md`; từ web1 chỉ nạp C3, từ UI1/fix1 cần cả hai đầu. Tài liệu dưới đây là lịch sử.**

# Bản sửa ESP ConTL v1.1-fix1 — HDZ463

> Tài liệu lịch sử fix1 để tra cứu USB/BLE. Bản hiện tại là **web1**, xem `WEB_VA_SCAN_WEB1.md` và **nạp lại C3 + S3/receiver**. Các số build/version trong tài liệu này nói về fix1, không phải bản hiện tại.

Giữ nguyên pinmap, menu/game, mapping và namespace lưu settings. Tên OS trên OLED vẫn là **ESP ConTL v1.1**; System info và Serial ghi `v1.1-fix1` để phân biệt firmware.

**Quan trọng:** lỗi USB không phản ứng và BLE reset chưa có log phần cứng để kết luận nguyên nhân duy nhất. Bản này sửa cách xử lý và bổ sung trạng thái chẩn đoán; đã biên dịch/kiểm thử logic trên máy tính, **chưa kiểm thử trên board thật**. Không thể dùng firmware để sửa cáp chỉ sạc, nhầm cổng USB hoặc nguồn yếu.

## A. Nâng cấp như thế nào?

1. Giải nén vào **thư mục mới**, không ghép thêm các tab BLE cũ vào sketch mới.
2. Giữ **esp32 by Espressif Systems 3.0.7**.
3. Library Manager → cài **NimBLE-Arduino 2.3.6**, tác giả h2zero. Các thư viện Adafruit giữ như bản trước.
4. Nạp lại `SmartController_C3/SmartController_C3.ino` cho C3. Board ESP32C3 Dev Module, CDC On Boot Enabled, Huge APP, flash đúng board.
5. Nạp lại `USB_Bridge_S3/USB_Bridge_S3.ino` cho S3. Board ESP32S3 Dev Module, **USB Mode = USB-OTG (TinyUSB)**, CDC On Boot Enabled.
6. Nạp lại `Receiver_Test/Receiver_Test.ino` cho bộ nhận thường nếu sử dụng.
7. Trên PC/điện thoại, **Forget/Remove thiết bị Bluetooth ESP ConTL cũ**, sau đó ghép lại vì stack BLE đã thay đổi.

Không cần xóa settings hoặc nhập MAC. Để Erase All Flash = Disabled nếu muốn giữ calibration/mapping. Không dùng file firmware C3 để nạp S3 hoặc ngược lại.

## B. Icon sạc nhấp nháy

- CHRG LOW, STDBY HIGH: icon `C` nhấp nháy.
- CHRG HIGH, STDBY LOW: icon `F` nhấp nháy, kể cả đã sạc xong mà vẫn cắm.
- Cả hai HIGH: icon `-` đứng yên.
- Cả hai LOW: icon `!` đứng yên, báo trạng thái không hợp lệ theo giả định mạch.
- Nhịp **500 ms hiện + 500 ms ẩn**, dùng `millis()`, không thêm `delay()` làm chậm điều khiển.

Đây là suy luận từ CHRG/STDBY giống phần cứng hiện có. Hai chân này không bảo đảm xác định VBUS trong mọi trạng thái của mọi module sạc. Nếu module không đổi hai tín hiệu khi rút/cắm, phải thêm mạch phát hiện VBUS an toàn; không nối 5 V thẳng vào GPIO.

File sửa: `SmartController_C3/ChargeIndicator.h`, `App.cpp`.

## C. S3 ping được nhưng PC không phản ứng

### Những thay đổi trong code

- Không còn gọi keyboard/mouse USB ngay trong handler xử lý gói điều khiển.
- Handler chỉ cập nhật trạng thái; vòng lặp riêng kiểm tra **USB mounted, không suspend, endpoint HID sẵn sàng** rồi gửi.
- Dùng đúng report của Arduino-ESP32 3.0.7: **keyboard 8 byte**, **relative mouse 5 byte** (có byte pan=0).
- Lấy kết quả `USBHID::SendReport()` thay vì bỏ qua lỗi của API keyboard/mouse trả về void.
- Gửi luân phiên keyboard/mouse, tối đa một report mỗi vòng lặp, timeout 10 ms mỗi lần gọi gửi.
- Phím/nút chuột được làm mới định kỳ, nhả phím qua watchdog 300 ms. Không phát lại một chuỗi delta chuột cũ khi PC vừa cắm lại/wake.
- PONG có thêm cờ trạng thái USB. **Định dạng gói vẫn 41 byte, protocol v1 không đổi.**

Các thay đổi này tăng khả năng xử lý host chưa sẵn sàng và cho biết lỗi xảy ra ở đâu; bản trước không hề kiểm tra được USB HID thực sự gửi thành công hay chưa.

### Đọc OLED của C3

Vào **USB via S3**, chọn **USB-S3**, thả hết bốn nút. Trạng thái cập nhật theo ping, khoảng mỗi giây:

| Màn hình | Ý nghĩa / cần làm |
|---|---|
| `USB: status pending` | Chưa có PONG mang trạng thái USB. Chờ 1–2 giây; nếu còn mãi, kiểm tra đã nạp bản fix1 cho S3 chưa |
| `USB: WAIT PC` | PC chưa cấu hình USB device của S3. Kiểm tra đúng **native USB**, cáp có data, USB Mode TinyUSB, PC có nhận thiết bị không |
| `USB: SUSPENDED` | USB host đang suspend. Đánh thức máy/cổng USB; code không tự wake PC |
| `USB: NO CONTROL` | Đường USB có mặt nhưng chưa có CONTROL USB hợp lệ gần đây. Thả nút chọn, kiểm tra mục USB via S3 và firmware hai bên |
| `USB: HID RETRY` | Host đã mounted nhưng chưa có xác nhận gửi thành công gần đây cho đủ keyboard/mouse. Xem log S3, rút/cắm lại native USB, kiểm tra driver/host |
| `USB: HID OK` | Có CONTROL hợp lệ gần đây và cả keyboard/mouse đã báo gửi thành công trong khoảng 1 giây vừa qua |
| `Release keys B:...` | C3 còn thấy nút bị giữ nên đang gửi NEUTRAL, chưa bật đầu ra. Thả nút hoặc vào Input test kiểm tra dây/switch |

Dòng `RX:1 K:1 M:1` tương ứng: CONTROL USB còn mới / keyboard TX thành công gần đây / mouse TX thành công gần đây. K/M là kết quả truyền USB, không phải khẳng định ứng dụng/game đích hỗ trợ bàn phím/chuột.

### Kiểm tra trên PC đúng cách

1. Cắm S3 vào PC qua **cổng USB native** của board, không chỉ cổng UART. Native dùng GPIO19 D− và GPIO20 D+; không tự nối dây thêm nếu board đã có cổng này.
2. Dùng cáp đã biết có truyền dữ liệu. Ping qua ESP-NOW vẫn chạy dù USB chỉ cấp nguồn hoặc hoàn toàn không nối PC.
3. PC cần nhận thiết bị HID, tên USB được đặt `ESP ConTL S3 HID` (cách hiển thị tên phụ thuộc OS).
4. C3 vào USB via S3. Chờ trạng thái.
5. Mở trình soạn thảo trống, **đưa con trỏ/focus vào ô nhập**. JOY1 lên mặc định là W, BTN R là Space. JOY2 mặc định di chuyển chuột.
6. Nếu `HID OK` nhưng không thấy gì: kiểm tra mapping, J2 mode, Input test, host/game có chấp nhận keyboard/mouse không. Đây không phải Xbox/XInput.

Không cần mở Serial Monitor để HID hoạt động. Có thể mở để chẩn đoán, nhưng lúc thử gõ cần chọn đúng cửa sổ test, tránh gửi Enter/phím tắt vào cửa sổ không mong muốn.

### Log S3 mới

Ví dụ minh họa, **không phải số đo trên phần cứng của bạn**:

```text
[USB] mounted=1 suspended=0 RX=120 active=1 K_OK=48 M_OK=70 err=0 modeErr=0 k0=1A mod=00 dx=0 dy=0 mb=0
```

- `mounted`: host đã cấu hình USB device.
- `RX`: số CONTROL có cờ USB được chấp nhận.
- `K_OK/M_OK`: số lần gửi report báo thành công, có cả report trạng thái nghỉ/nhả phím.
- `err`: số lần gửi report trả thất bại/timeout.
- `modeErr`: gói CONTROL thiếu cờ USB; chọn nhầm chế độ hoặc firmware không đồng bộ.
- `k0`: mã HID phím đầu tiên ở hệ hex; W=1A, Space=2C, 00=không có phím ở slot đó. `mod` là modifier.
- `dx/dy/mb`: delta và nút chuột của gói vừa nhận, không phải delta còn đợi gửi.

Nếu vẫn không điều khiển: gửi **ảnh màn hình C3**, **tên board S3/ảnh cổng đang cắm** và vài dòng log này khi đẩy JOY1 lên / JOY2 sang phải. Không chỉ gửi kết quả ping.

## D. Receiver in Serial khi chưa kết nối

Đã bỏ:

- Banner AP khởi tạo từ lớp nhận chung.
- Luồng `SAFE seq=0 J1=(0,0)...` lặp mỗi 200 ms khi chưa nhận điều khiển.

Hành vi mới:

1. Chưa nhận CONTROL hợp lệ: ứng dụng im lặng. Chỉ handshake hoặc ping cũng không in joystick.
2. Có CONTROL: in `CONNECTED: receiving control`, sau đó in RX tối đa mỗi 200 ms **nếu đã có dữ liệu mới**.
3. Tạm dừng hoặc mất CONTROL quá 300 ms: in **một lần** `STOP: neutral / control timeout`; ngừng stream.
4. Nhận lại CONTROL: tiếp tục stream.

**Boot ROM của ESP32 vẫn có thể in thông tin khi reset**, và lỗi khởi tạo thật vẫn được in. Đây không phải dữ liệu nhận giả. Không cần sửa eFuse để xóa những dòng boot này.

## E. BLE làm ESP32-C3 restart

### Đã thay đổi

- Đổi Bluedroid `BLEDevice/BLEHIDDevice` sang **NimBLE-Arduino 2.3.6**; không trộn hai stack.
- Tắt chế độ Wi-Fi trước khi vào BLE.
- Kiểm tra heap và khối trống lớn trước lần init đầu. Nếu không đủ, hiển thị `Low heap` thay vì cố khởi tạo.
- Tạo server/HID/service/callback **một lần mỗi boot**, tái sử dụng khi vào menu lại. Không delete/deinit đối tượng khi callback có thể còn đang chạy.
- Callback chỉ ghi cờ/trạng thái; main loop xử lý yêu cầu quảng bá lại/bảo mật/ngắt kết nối.
- Chỉ gửi notify khi liên kết đã được mã hóa và host đăng ký report đó; cập nhật cache khi notify báo thành công.
- Thêm log heap ở các giai đoạn và reset reason ở lần boot tiếp theo.

Đổi stack giúp giảm footprint bản build, nhưng **không đủ bằng chứng để kết luận lỗi cũ chắc chắn do hết RAM**. Nếu nguồn sụt áp, lỗi board hoặc lỗi khác thì vẫn có thể restart.

### Thử lại

1. Cài NimBLE 2.3.6 và nạp đúng sketch mới.
2. Forget thiết bị ESP ConTL cũ trên host, sau đó vào Bluetooth và ghép lại.
3. Theo dõi `Pair on host` → `Pairing...` / `Host config` → `HID ready`.
4. Thử thoát bằng tổ hợp 4 nút rồi vào BLE lại; thử chuyển qua lại BLE/ESP Remote/USB.
5. Nếu còn restart, mở Serial Monitor C3 **115200**, vào BLE rồi gửi log gồm phần `[BLE]`, thông báo panic/backtrace nếu có, và `[BOOT]` của lần khởi động lại.

```text
[BLE] NimBLE init heap=... largest=...
[BLE] services ready heap=...
[BOOT] reset=PANIC (...) heap=...
```

- `BROWNOUT`: kiểm tra nguồn, dây, pin/boost/regulator và tải; **không tắt brownout detector để che lỗi nguồn**.
- `PANIC`: cần backtrace để xác định lỗi runtime.
- `TASK_WDT` / `INT_WDT` / `WDT`: cần log trước reset để tìm đoạn bị chặn/watchdog.
- `SOFTWARE`: có thể là restart chủ động hoặc đường xử lý lỗi; cần log trước đó.
- `POWERON`: thường cấp nguồn/reset nguồn; không tự chứng minh lỗi firmware.

Tên reset reason mô tả loại reset, không thay thế việc chẩn đoán nguyên nhân gốc.

## F. Kiểm thử đã làm

Xem `verification/BUILD_AND_TEST.md` và log kèm theo:

- Biên dịch C3 + S3 + receiver trên core 3.0.7.
- Kiểm thử logic game cũ được chạy lại.
- Kiểm thử mới: blink C/F, đứng yên khi không có tín hiệu, pipeline mapping C3 → định dạng report S3, nhả phím, timeout, không phát lại delta chuột, mode sai và retry.

Chưa kiểm thử điện, USB enumeration, BLE pairing, radio và việc hết reset trên board của bạn. Các test host không mô phỏng TinyUSB/NimBLE thật.
