> **Bản hiện tại: web2. Xem `WEB_CONSOLE_WEB2.md`; từ web1 chỉ nạp C3, từ UI1/fix1 cần cả hai đầu. Tài liệu dưới đây là lịch sử.**

# ESP ConTL v1.1-ui1 — Giao diện chuyển động

Bản này phát triển từ **v1.1-fix1**, giữ nguyên pinmap, protocol ESP-NOW, sửa USB/BLE của fix1, 11 mini-game và cấu trúc dữ liệu settings.

> **Tài liệu lịch sử UI1**, giữ để giải thích hiệu ứng/OLED. Với **web1 hiện tại phải nạp lại C3 + S3/receiver**, xem `WEB_VA_SCAN_WEB1.md`. Quy tắc chỉ nạp C3 chỉ áp dụng cho lần nâng fix1 → UI1 trước đây; số chấm Home hiện tại đã tăng từ 5 lên 6.

## 1. Hiệu ứng mới

- **Menu trượt trái/phải 220 ms**, nhanh lúc đầu rồi chậm dần khi vào vị trí. Có thể bấm tiếp trong lúc đang chuyển, không phải đợi animation kết thúc.
- Thanh OS/sạc trên cùng và vùng điều hướng dưới cùng **được giữ cố định**, không trượt theo nội dung.
- Card menu bo góc mới: icon ở trái, nội dung ở phải, đường phân cách và mũi tên L/R.
- Năm chấm Home có dấu chọn di chuyển mềm giữa các mục.
- Icon Wi-Fi có sóng quét, USB có điểm chạy, Bluetooth có điểm nhấp nháy, gamepad chuyển động nhẹ, settings quay chậm.
- **11 icon mini-game riêng**, vẽ trực tiếp bằng hình học, không cần ảnh/thẻ nhớ.
- Tên/mô tả dài **chạy chữ qua lại** sau khoảng nghỉ, được cắt đúng khung để không đè icon/viền. Trong menu game hiển thị gợi ý cách chơi.
- Màn hình kết nối có các bước **SCAN → JOIN → LINK** theo trạng thái thật và thanh chờ chuyển động. Không hiển thị phần trăm kết nối giả.
- Màn hình khởi động có intro khoảng 1 giây; nhấn một SW joystick để bỏ qua. Không dùng `delay(700)` như bản trước.
- Thông báo như “Mapping saved” trượt lên rồi xuống.
- Hộp xác nhận Yes/No có khung chọn chạy mềm.
- Giữ bốn nút: vòng tiến trình tròn chạy đủ 3 giây, kèm **PAUSED** và đếm ngược. Khi giữ, đầu ra vẫn về trung tính như fix1.
- Giữ L hoặc R trong menu trên 450 ms để duyệt liên tục, mỗi 160 ms một mục. Không áp dụng auto-repeat menu cho nút chơi game/điều khiển.

`UI_preview.gif` là **mô phỏng phần mềm** của một số màn hình/hiệu ứng, không phải video quay OLED thật hay kết quả đo tốc độ trên C3. Font mô phỏng dựa trên classic font của Adafruit GFX; vẽ hình/nhịp GIF có thể khác đôi chút so với màn hình thật.

## 2. Mượt hơn nhưng ưu tiên điều khiển

### Vấn đề của cách gửi cũ

Một frame SSD1306 128×64 là 1.024 byte. Gọi `display.display()` để đẩy cả frame qua I²C 400 kHz thường chiếm cỡ 24 ms cộng overhead; gọi liên tục trong vòng lặp điều khiển gây khoảng chờ dài.

### Cách mới

- `OledPump.h` chụp một frame vào buffer riêng, sau đó truyền **từng khối 32 byte**.
- Mỗi vòng lặp chỉ gửi một giao dịch I²C ngắn. 32 byte dữ liệu ở 400 kHz thường mất khoảng 0,8 ms cộng overhead; **Wire vẫn là API đồng bộ**, không phải DMA hay I²C bất đồng bộ hoàn toàn.
- Xử lý ESP-NOW và BLE được gọi xen giữa các khối I²C, thay vì chờ xong cả frame.
- Joystick/nút và bước game/điều khiển có lịch riêng, mục tiêu **20 ms/tick**, không chạy bù sau tạm dừng.
- Menu/game đặt lịch vẽ **33 ms/frame, khoảng 30 FPS mục tiêu**. Màn hình Remote/BLE đặt 80 ms/frame để ưu tiên điều khiển; khi giữ tổ hợp thoát thì tăng tần số vẽ vòng đếm ngược.
- Không thay frame đang gửi dở. Nhấn menu nhanh sẽ cập nhật đích animation chứ không tạo hàng đợi dài các hiệu ứng.
- I²C giữ **400 kHz**, không ép OLED lên 1 MHz. Timeout Wire đặt 8 ms; gặp NACK/timeout thì bỏ frame hiện tại, thử frame tiếp theo và tăng bộ đếm lỗi.
- Không thêm `delay()` để chờ animation. Vòng lặp có `yield()` khi gửi OLED và nghỉ 1 ms khi bus đang rảnh; các thao tác đồng bộ có sẵn như lưu NVS, lấy mẫu calibration và init NimBLE vẫn có thể tạo khoảng dừng.

**Không bảo đảm 30 FPS/50 Hz trên mọi board**: phụ thuộc OLED, bus, core, radio, nguồn và tải. Kiểm tra số khung hình thực tế bằng System info. Không hứa 60 FPS trên cấu hình OLED I²C này.

## 3. Settings mới

### UI motion

Vào **Settings → UI motion**, nhấn JOY1 SW hoặc JOY2 SW:

- `Animated`: bật trượt menu, icon động, marquee và toast động.
- `Minimal`: tắt các hiệu ứng trang trí; giữ menu, chức năng và tín hiệu trạng thái.

Tùy chọn lưu riêng bằng Preferences key `ui_fx`, mặc định bật. Không đổi layout blob settings cũ nên calibration/mapping trước đó vẫn được đọc. Reset settings đưa UI motion về bật.

**Icon sạc nhấp nháy và tiến trình giữ nút vẫn hoạt động** khi tắt hiệu ứng, vì đó là thông tin trạng thái, không chỉ trang trí.

### System info

Có thêm trang thứ 5 **OLED / UI STATUS**:

- `OLED ... frames/s`: số frame đã gửi thành công trong cửa sổ đo gần nhất khoảng 1 giây.
- `I2C errors`: tổng số giao dịch bị NACK/timeout kể từ boot.

Đây là số frame đẩy lên bus, không phải máy đo tần số quét tấm nền OLED. Nếu `I2C errors` tăng liên tục, kiểm tra OLED, dây SDA/SCL, pull-up, địa chỉ 0x3C và nguồn.

## 4. Cách nạp

1. Mở `SmartController_C3/SmartController_C3.ino` trong **thư mục UI1 mới**. Giữ toàn bộ `.h/.cpp` cùng thư mục.
2. Dùng đúng môi trường fix1:
   - Arduino-ESP32 **3.0.7**
   - NimBLE-Arduino **2.3.6**
   - Adafruit SSD1306 **2.5.13**
   - Adafruit GFX **1.11.11**, BusIO **1.17.4**
3. Board **ESP32C3 Dev Module**, **USB CDC On Boot Enabled**, **Huge APP**, dung lượng flash đúng board.
4. Không cần xóa toàn bộ flash để nâng cấp từ fix1; giữ NVS nếu muốn giữ cấu hình.
5. Nạp C3 rồi kiểm tra Home, Settings, từng chế độ kết nối và game.

Bản UI1 **không đổi stack/descriptor BLE so với fix1**, nên không bắt buộc quên và ghép lại chỉ vì nâng cấp giao diện. Nếu đi từ bản v1.1 gốc chưa có fix1, xem thêm `BAN_SUA_FIX1.md` để nâng cấp NimBLE/S3 trước.

## 5. File thay đổi

- `App.cpp`: bố cục, lịch logic/vẽ, màn hình startup, carousel, thông báo, pause overlay, UI motion.
- `UiMotion.h`: ease-out fixed-point, chuyển framebuffer theo hướng; giữ header/footer cố định.
- `UiWidgets.*`: icon, icon game, vòng tiến trình, spinner, loading bar, text clipping và marquee.
- `OledPump.h`: gửi SSD1306 thành giao dịch nhỏ 32 byte, snapshot riêng, đếm lỗi.

Buffer/UI được thiết kế riêng cho **SSD1306 128×64, rotation=2, I²C 0x3C** như phần cứng hiện tại. Không đổi sang SH1106, kích thước khác hoặc rotation khác mà chưa sửa driver/compositor.

Protocol, `Input.*`, `Games.*`, `BleOutput.*`, `ControllerLink.*`, S3 và Receiver giữ nguyên so với fix1. OLED thêm khoảng 3 KB buffer tĩnh cho chuyển cảnh và gửi dữ liệu.

## 6. Kiểm tra trên board

- [ ] Bấm L/R và giữ L/R: không phải đợi animation, mục chọn khớp nội dung.
- [ ] Vào game ngay trong khi chuyển menu: game nhận nút đúng sau khi thả SW.
- [ ] Giữ đủ bốn nút: đầu ra trung tính ngay khi tổ hợp được nhận, vòng đếm ngược hoạt động; thả sớm/thả hết để tiếp tục.
- [ ] Vào Settings → UI motion, tắt/bật rồi reboot: tùy chọn được nhớ.
- [ ] Đảo màu, test hai joystick và calibration còn hoạt động.
- [ ] Cắm/rút sạc: icon blink vẫn như fix1 theo CHRG/STDBY.
- [ ] Remote/USB/BLE chạy được; thử giữ phím/di chuyển chuột và thoát để xác nhận nhả phím.
- [ ] Vào BLE từ Home: thấy Starting BLE rồi Pair on host/HID ready, không mắc ở màn hình chờ.
- [ ] System info có FPS và `I2C errors=0` trong điều kiện bus tốt.

Đã kiểm tra biên dịch và host tests; **chưa đo FPS/độ trễ hoặc thử OLED, radio và BLE trên phần cứng thật**. Test phần mềm không thay thế checklist này.
