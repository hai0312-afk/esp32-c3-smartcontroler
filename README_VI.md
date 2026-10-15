# ESP ConTL v1.1-web5 — HDZ463

**Đọc `WEB5_HUONG_DAN.md` trước. Web có 26 game (thêm 10 solo + 5 hai người), OLED giữ 11 game. Hai người: P1 JOY1/SW1/L, P2 JOY2/SW2/R; giữ L+R 0,7s mở menu. Có Wake Lock/helper Windows tùy chọn, fullscreen ở PIN và logo/intro/animation TV mới. Đã dùng đủ web3/web4: chỉ nạp lại C3.**

**Bộ firmware Arduino cho Smart Controller ESP32-C3 + cầu USB ESP32-S3 + bộ nhận ESP32 mẫu.**

> Trạng thái: đã kiểm tra biên dịch bằng Arduino-ESP32 **3.0.7** và chạy kiểm thử logic trên máy tính. **Chưa nạp/chạy trên phần cứng thật** trong phiên làm việc này. BLE pairing, USB enumeration, tín hiệu sạc, ADC và chất lượng sóng cần kiểm tra theo checklist bên dưới.

## 1. Có gì trong bộ code?

| Thư mục | Nạp cho | Chức năng |
|---|---|---|
| `SmartController_C3` | ESP32-C3 SuperMini, flash 4 MB | OLED, joystick/nút, ESP-NOW, Bluetooth bàn phím/chuột, cài đặt, 11 mini-game OLED + 26 game màu qua web |
| `USB_Bridge_S3` | ESP32-S3 có cổng USB native | Phát `espH_USB-S3`, nhận ESP-NOW và xuất bàn phím/chuột USB |
| `Receiver_Test` | ESP32 / ESP32-C3 / ESP32-S3 có Wi-Fi | Phát `espH_TestReceiver`, in joystick/nút qua Serial, trả lời ping, failsafe |
| `web`, `tools` | PC / tài nguyên nhúng C3 | Nguồn web offline, tạo WebAssets.h và server xem thử bằng bàn phím |
| `tests` | Máy tính có g++ | Kiểm thử logic game, HID mapping, debounce, calibration và định dạng gói; không giả lập radio/USB/BLE |
| `verification` | Đọc trên máy tính | Kết quả biên dịch và kiểm thử |

Mở **một file `.ino` trong đúng thư mục tương ứng**. Giữ toàn bộ `.h` và `.cpp` cùng thư mục sketch, không chỉ chép riêng `.ino`.

### Sơ đồ hoạt động

```text
                            +--> ESP32 nhận mẫu --> Serial / logic thiết bị của bạn
C3 + OLED + 2 joystick -----|       ESP-NOW
                            |
                            +--> ESP32-S3 ----------> Máy tính / điện thoại USB host
                            |       ESP-NOW           cáp USB native, HID
                            |
                            +-----------------------> Máy tính / điện thoại hỗ trợ BLE HID
                                      Bluetooth LE
```

- C3 **không** có USB OTG/HID native. USB của C3 dùng nạp/debug, không biến thành bàn phím USB bằng firmware này.
- Chế độ USB là **C3 không dây → S3 → USB host**, không cần nối UART hay GPIO giữa C3 và S3.
- S3 là **USB device**, máy tính/điện thoại là **USB host**. Không dùng cổng USB-UART của S3 thay cho USB native.
- USB và Bluetooth xuất **bàn phím + chuột**, **không** giả lập XInput, Xbox, PlayStation hay HID gamepad analog.
- Các chế độ được sử dụng luân phiên: BLE, ESP-NOW/USB via S3 và Web Games không hoạt động đồng thời. Web Games nối trực tiếp C3 → PC qua Wi-Fi, không cần S3.
- Đây không phải điều khiển vạn năng cho TV/IR, thiết bị 433 MHz, mọi đồ gia dụng hoặc mọi ESP32 có sẵn. Thiết bị đích phải chạy firmware tương thích và có logic điều khiển riêng.

## 2. Phần cứng và pinmap C3

Giữ theo `pinmap.txt` được cung cấp và ví dụ OLED của bạn:

| Thành phần | GPIO | Cách đấu |
|---|---:|---|
| JOY1 X | 0 | Ngõ ra analog, trong phạm vi 0–3.3 V |
| JOY1 Y | 1 | Ngõ ra analog |
| JOY2 X | 3 | Ngõ ra analog |
| JOY2 Y | 2 | Ngõ ra analog; chú ý chân strapping |
| JOY1 SW | 10 | Nút nối xuống GND, `INPUT_PULLUP` |
| JOY2 SW | 6 | Nút nối xuống GND, `INPUT_PULLUP` |
| BTN L | 7 | Nút nối xuống GND, `INPUT_PULLUP` |
| BTN R | 20 | Nút nối xuống GND, `INPUT_PULLUP` |
| CHRG | 4 | Trạng thái sạc active-low, mức logic an toàn 3.3 V |
| STDBY | 5 | Trạng thái sạc xong active-low, mức logic an toàn 3.3 V |
| OLED SDA | 8 | I²C |
| OLED SCL | 9 | I²C |
| OLED | `0x3C` | SSD1306 128×64, xoay `setRotation(2)` |

### Lưu ý điện quan trọng

1. **Cấp joystick bằng 3.3 V**, không cấp 5 V rồi đưa analog trực tiếp vào ESP32. Chung GND cho các phần trên tay cầm.
2. GPIO **2, 8, 9 là chân strapping** của C3. OLED và joystick gắn trên các chân này có thể ảnh hưởng khởi động/nạp tùy board và mức điện áp lúc reset. Nếu lỗi boot, kiểm tra sơ đồ board, pull-up và thử tháo ngoại vi; tránh giữ BOOT/SCL9 thấp ngoài lúc nạp. Không tự thêm pull-up mạnh vào trục analog vì sẽ làm sai số đo.
3. Dùng **USB CDC On Boot = Enabled** với C3 SuperMini có USB native. GPIO20 đang là BTN R, không đồng thời nối nó với TX của USB-UART ngoài đang phát tín hiệu.
4. CHRG/STDBY được giả định là ngõ ra **open-drain active-low**. Chỉ đấu khi đã kiểm tra điện áp: một số module sạc kéo LED/status lên **5 V**; phải xử lý mạch phù hợp trước khi nối GPIO.
5. Hai chân CHRG/STDBY **không đo được phần trăm pin, điện áp pin hay bảo đảm nhận biết VBUS trong mọi trạng thái**. Muốn biết chắc “đang cắm USB” cần thêm mạch VBUS detect; muốn đo pin cần chia áp/IC đo pin và chân thích hợp. Không nối pin Li-ion 4.2 V thẳng vào GPIO.
6. Board sạc cần bảo vệ pin và mạch nguồn/load-sharing phù hợp nếu vừa sạc vừa chạy. Firmware không thay thế chức năng bảo vệ phần cứng.

### Ký hiệu nguồn ở góc trên phải

| CHRG | STDBY | OLED | Ý nghĩa suy ra |
|---|---|---|---|
| LOW | HIGH | `C` | Đang sạc |
| HIGH | LOW | `F` | Báo sạc xong |
| HIGH | HIGH | `-` | Không có tín hiệu sạc; **không khẳng định chắc chắn đã rút USB** |
| LOW | LOW | `!` | Trạng thái không hợp lệ theo giả định mạch này |

Tên OS ở góc trái, biểu tượng pin/status ở góc phải. **Fix1:** icon C/F nhấp nháy 500 ms hiện/500 ms ẩn; icon `-` hoặc `!` đứng yên. Không hiển thị “3.7 V” hay phần trăm giả.

## 3. Cài Arduino IDE và thư viện

1. Dùng Arduino IDE 2.x.
2. Trong Preferences → Additional Boards Manager URLs, thêm:
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
3. Boards Manager: cài **esp32 by Espressif Systems, phiên bản 3.0.7**.
4. Library Manager:
   - **Adafruit SSD1306 2.5.13**
   - **Adafruit GFX Library 1.11.11**
   - **Adafruit BusIO 1.17.4**
   - **WebSockets 2.6.1** của Markus Sattler / Links2004 (**mới cho Web Games**)
   - **NimBLE-Arduino 2.3.6** của h2zero (**mới, bắt buộc cho C3**)
5. `WiFi`, `Preferences`, `USB` và ESP-NOW dùng bản trong core 3.0.7. Bluetooth dùng **NimBLE-Arduino 2.3.6**, không dùng Bluedroid `BLEDevice.h` của bản cũ. Không cần cài ESP32-BLE-Keyboard hay thư viện USB bên thứ ba; không trộn tab BLE cũ vào sketch mới.

Phiên bản được chốt để tránh khác biệt callback/API giữa Arduino-ESP32 2.x và các bản 3.x khác. Nếu cập nhật core, cần biên dịch và kiểm thử lại.

### Nạp C3

Mở `SmartController_C3/SmartController_C3.ino`.

- Board: **ESP32C3 Dev Module**
- USB CDC On Boot: **Enabled**
- CPU: **160 MHz**
- Flash Size: **4 MB** nếu đúng phần cứng của bạn
- Partition Scheme: **Huge APP (3MB No OTA/1MB SPIFFS)**
- Upload Speed: 460800 hoặc 115200 nếu nạp không ổn định
- Chọn cổng thực tế của C3 rồi Upload

Tiếp tục dùng Huge APP để có dư dung lượng khi phát triển thêm; bản fix1 đã giảm dung lượng chương trình nhờ đổi stack BLE. Firmware không dùng OTA. Nếu board không đúng flash 4 MB, không chọn bừa thông số này.

Nếu không vào chế độ nạp: giữ BOOT, nhấn/thả RESET, thả BOOT rồi nạp; sau khi nạp nhấn RESET khi cần. Tùy SuperMini, BOOT nằm trên GPIO9 và có thể bị ảnh hưởng bởi OLED đang đấu.

### Nạp S3 cho cầu USB

Mở `USB_Bridge_S3/USB_Bridge_S3.ino`.

- Board: **ESP32S3 Dev Module** hoặc đúng biến thể tương ứng
- USB Mode: **USB-OTG (TinyUSB)** — không phải Hardware CDC/JTAG
- USB CDC On Boot: **Enabled**
- Partition Scheme: **Huge APP**; dung lượng flash/PSRAM chọn đúng board
- PSRAM không bắt buộc
- Upload Mode/cổng nạp chọn theo cổng UART hoặc USB native bạn thực sự dùng; firmware HID yêu cầu USB Mode TinyUSB như trên

Sau khi nạp, cắm **cổng USB native của S3** vào máy tính bằng cáp có dữ liệu. Trên S3, native USB dùng GPIO19 = D−, GPIO20 = D+. Nếu board đã có cổng native thì dùng cổng đó, không tự đi dây USB bằng dây dài trên breadboard. Với điện thoại cần hỗ trợ USB host và adapter/cáp phù hợp.

### Nạp bộ nhận test

Mở `Receiver_Test/Receiver_Test.ino`, chọn đúng board ESP32 thực tế.

- ESP32 thường: **ESP32 Dev Module**, Serial Monitor **115200 baud**.
- Nếu là C3: ESP32C3 Dev Module, bật USB CDC như trên khi dùng USB native.
- Nếu là S3: chọn đúng USB/Serial của board để xem log.

Fix1 không in RX/SAFE định kỳ khi chưa nhận CONTROL; handshake và PING đơn thuần cũng không bật luồng log joystick. Thông báo boot ROM của chip hoặc lỗi khởi tạo có thể vẫn xuất hiện. Không cần OLED hay joystick trên bộ nhận. Code test **không điều khiển GPIO tải**; chỉ in thông tin và giữ trạng thái đầu ra mẫu.

## 4. Giao diện và thao tác

OLED dùng chữ ASCII/tiếng Anh ngắn để phù hợp font mặc định và 128×64; tài liệu này giải thích bằng tiếng Việt.

### Menu chính

- **BTN L / BTN R**: chuyển mục trái/phải.
- **JOY1 SW hoặc JOY2 SW**: chọn.
- Sáu mục: `ESP Remote`, `USB via S3`, `Bluetooth`, `Mini Games`, `Web Games`, `Settings`.
- Menu UI1 có card bo góc, chuyển cảnh trượt, icon động, marquee cho chữ dài và thanh OS/nguồn cố định. Giữ L/R để duyệt nhanh. Xem `UI_preview.gif` (mô phỏng lịch sử UI1, chưa có mục Web Games).
- Menu con có `Back`; ngoài ra dùng tổ hợp 4 nút để về Home từ mọi màn hình.

### Phím thoát toàn cục

Giữ đồng thời **BTN L + BTN R + JOY1 SW + JOY2 SW**:

1. Khi nhận đủ 4 nút đã debounce: game ngừng cập nhật, ESP-NOW gửi `NEUTRAL`, BLE nhả phím/chuột, Web Games gửi pause/trung tính.
2. OLED hiển thị **PAUSED**, vòng tiến trình tròn và đếm `3 → 2 → 1`.
3. Thả trước 3 giây: chương trình tiếp tục **sau khi đã thả hết cả 4 nút**, tránh lọt nút thoát vào game hoặc host.
4. Giữ đủ 3 giây: về Home, dừng kết nối chế độ hiện tại. Chờ thả hết nút mới nhận thao tác mới.
5. Thời gian game không chạy bù sau khi tạm dừng. Các nút bấm rời rạc trước khi đủ tổ hợp vẫn có tác dụng bình thường.

Trong chế độ điều khiển máy thật, “tạm dừng” nghĩa là đầu ra **trung tính/dừng**, không giữ lệnh ga cũ. Khi thả tổ hợp sớm, thiết bị có thể tiếp tục nhận lệnh joystick hiện tại — chỉ thử trên hệ thống an toàn.

## 5. Kết nối ESP32 và ping

### Test đầu tiên

1. Nạp/cấp nguồn bộ `Receiver_Test` và mở Serial Monitor 115200.
2. Trên C3 vào **ESP Remote**.
3. Chờ quét, chọn **TestReceiver**. OLED bỏ tiền tố `espH_` khi hiển thị cho gọn.
4. Chờ `Joining Wi-Fi` → `Exchanging MAC` → xác nhận ESP-NOW. Đưa hai cần về giữa, nhấn J1/J2 SW rồi thả hết nút để arm. Nối lại sau lỗi cũng cần xác nhận này.
5. Di chuyển hai joystick, nhấn từng nút. Bộ nhận sẽ in dạng:

```text
RX seq=... J1=(-650,0) J2=(0,720) L=0 R=1 SW1=0 SW2=0
```

6. OLED hiển thị RTT và `Loss` của ping. Ping tự gửi mỗi khoảng **250 ms**, không chiếm nút đang dùng điều khiển.
7. Thử tắt C3: bộ nhận phải in **một lần** `STOP: neutral / control timeout` và dừng đầu ra sau khoảng **300 ms** tính từ gói điều khiển cuối, cộng thời gian vòng lặp.

### Discovery và bắt tay

- Chỉ liệt kê AP 2.4 GHz có SSID bắt đầu đúng `espH_`; phân biệt chữ hoa/thường.
- **Không thể quét mọi ESP32** nếu chúng không phát SSID này. SSID đúng tiền tố cũng chưa chứng minh đó là firmware tương thích.
- Tối đa **24 mục** trong một lượt quét; một thiết bị được điều khiển tại một thời điểm.
- Kết nối theo BSSID và kênh của AP được chọn; SSID trùng nhau vẫn có thể là các mục riêng.
- Mật khẩu demo AP: **`ESPConTL11`**. Đổi trong cả ba bản `Protocol.h` nếu sử dụng thực tế.
- C3 gửi UDP `HELLO`, gồm MAC STA của C3 và mã phiên ngẫu nhiên.
- Bộ nhận trả UDP `WELCOME`, gồm **MAC SoftAP của bộ nhận**, kênh và loại thiết bị.
- Hai bên thêm peer ESP-NOW trong **RAM**, dùng kênh đã thống nhất. **Không ghi MAC peer vào Preferences/EEPROM.**
- AP của bộ nhận duy trì kênh **6**. Web3: C3 chủ động rời association Wi-Fi sau bắt tay, giữ radio STA và khóa kênh đã học; không cần duy trì kết nối Wi-Fi AP. Dữ liệu điều khiển và ping sau bắt tay truyền qua **ESP-NOW**, không phải UDP.
- Web1: C3 dùng **STA MAC / WIFI_IF_STA**, receiver dùng **SoftAP MAC / WIFI_IF_AP**, lấy lúc chạy qua bắt tay. Nạp lại cả hai đầu; không nhập tay MAC.
- Quét hai pass active (CH6 rồi toàn dải); nếu vẫn không thấy espH_, thêm pass passive. Có chờ ổn định, timeout, recovery cờ scan cũ và log AP/espH. Xem `WEB_VA_SCAN_WEB1.md` mục 5–6.
- Sau lỗi ESP-NOW, web3 thử nối lại tối đa 3 lần mỗi đợt. Đầu ra giữ neutral, phải center + nhấn/thả J1/J2 để rearm. Hết lượt thử có thể quét/chọn lại; không tự khôi phục đầu ra đang giữ.

### Gói điều khiển

`Protocol.h` là định dạng dùng chung, packed, phiên bản 1:

| Trường | Nội dung |
|---|---|
| `axis[0..3]` | J1X, J1Y, J2X, J2Y; `int16_t`, −1000…1000 sau hiệu chuẩn, đảo trục, deadzone |
| `buttons` | bit0=L, bit1=R, bit2=JOY1 SW, bit3=JOY2 SW |
| `session` | Mã phiên chống nhầm phiên/gói cũ; không phải cơ chế xác thực bảo mật |
| `seq` | Số thứ tự; loại gói trùng/cũ, xử lý quay vòng |
| `type` | CONTROL / PING / PONG / NEUTRAL |
| `flags` | Bit USB: S3 được phép áp dụng báo cáo HID |
| `hid` | Modifier, tối đa 6 phím HID, nút chuột và delta chuột |

- `Hello` 20 byte; `Packet` 41 byte; có magic/version/length kiểm tra.
- ADC gốc đọc 12-bit; giá trị **gửi đi là chuẩn hóa**, không phải raw 0–4095. Có thể đọc raw trong `Input::raw` nếu bạn muốn mở rộng giao thức.
- Chu kỳ xử lý mục tiêu 20 ms, **không bảo đảm 50 Hz**. UI1 gửi OLED từng khối 32 byte để giảm khoảng chặn; radio, BLE, I²C và thao tác đồng bộ khác vẫn ảnh hưởng tần số thực tế.
- RTT đo từ trước `esp_now_send(PING)` đến callback nhận PONG trên C3, gồm cả xử lý/đợi bên nhận. Không phải độ trễ một chiều, cũng không phải độ trễ toàn tuyến đến màn hình game trên PC.
- Web3: ping quá 350 ms được tính mất; PONG cũ quá 600 ms buộc neutral/rearm, quá 2 giây chuyển sang nối lại. `Loss` là số ping timeout, **không phải thống kê mất mọi gói điều khiển**.
- Bộ nhận có watchdog riêng: **300 ms không có CONTROL/NEUTRAL hợp lệ thì dừng/nhả phím**. Ping không làm mới watchdog điều khiển.
- Callback ESP-NOW chỉ chép dữ liệu vào queue; không vẽ OLED, Serial, USB, NVS hay chờ trong callback.

### Bảo mật và giới hạn an toàn

AP dùng mật khẩu demo, nhưng **ESP-NOW trong bản này chưa mã hóa** (`peer.encrypt=false`). MAC và session không thay thế xác thực; không dùng cho cửa khóa, máy móc nguy hiểm hoặc môi trường có người cố tình giả mạo. Trước khi triển khai cần cơ chế provision khóa/LMK phù hợp, xác thực, giới hạn đầu ra và nút dừng khẩn cấp độc lập. Không dùng MAC ngẫu nhiên công khai làm khóa mã hóa.

Failsafe là phần mềm và chỉ hoạt động khi vòng lặp bộ nhận còn chạy. Không coi đây là hệ thống an toàn cấp công nghiệp.

## 6. USB qua S3

1. Cắm native USB của S3 đã nạp firmware vào máy tính.
2. C3 → **USB via S3** → chọn **USB-S3**.
3. Fix1 hiển thị trạng thái USB lấy từ PONG bên S3; xem bảng trong `BAN_SUA_FIX1.md`. Firmware kiểm tra role USB; chọn nhầm `TestReceiver` sẽ báo **Not a USB bridge**.
4. Giữ hai cần ở giữa, nhấn J1/J2 SW rồi thả hết nút để arm. Mở trình soạn thảo trống hoặc công cụ kiểm tra bàn phím rồi thử.
5. S3 chuyển báo cáo HID nhận được thành bàn phím/chuột USB. Khi mất điều khiển 300 ms, S3 nhả phím/chuột.

Không cần nhập MAC thủ công. S3 không cần màn hình. Gán phím làm trên C3, có hiệu lực cho cả USB và BLE.

**Thử trên cửa sổ vô hại trước**, vì phím Enter/Esc, chuột và các modifier có thể tác động lên cửa sổ đang mở. Một số console/game chỉ chấp nhận gamepad/XInput sẽ không hoạt động với chế độ bàn phím/chuột này.

## 7. Bluetooth

1. C3 → **Bluetooth**.
2. Trên PC/điện thoại hỗ trợ **Bluetooth LE HID**, tìm và ghép đôi **ESP ConTL v1.1**.
3. OLED lần lượt có thể báo Pair on host, Pairing..., Host config, HID ready. Chỉ gửi notify sau khi kết nối được mã hóa và host đăng ký nhận report.
4. Dùng cùng mapping như USB. JOY2 mặc định di chuyển chuột.
5. Giữ 4 nút để thoát; firmware nhả phím và ngắt kết nối.

Code fix1 dùng NimBLE HID với report bàn phím và chuột, không dùng Bluetooth Classic. Sau khi nâng cấp từ bản Bluedroid cũ, hãy quên thiết bị trên host rồi ghép lại. Khả năng tương thích tùy hệ điều hành. Nếu trước đây đã ghép với firmware có report descriptor khác, hãy **Forget/Remove device trên host và ghép lại**. Xóa toàn bộ flash C3 nếu cần xóa dữ liệu bonding cũ, nhưng thao tác đó cũng xóa settings.

BLE có thể lưu **bonding Bluetooth** trong NVS theo cơ chế của stack. Yêu cầu “không lưu MAC” được áp dụng cho **peer ESP-NOW**, không cấm khóa bonding BLE. Mục Reset settings không xóa bonding BLE.

## 8. Settings và mapping

| Mục | Thao tác |
|---|---|
| Key mapping | Chọn 1 trong 12 đầu vào; nhấn SW để sửa; L/R đổi action; **J1 SW lưu, J2 SW hủy** |
| OLED invert | SW bật/tắt đảo màu phần cứng SSD1306 |
| Input test | Hai vòng tròn joystick, hai nút L/R; SW tô đặc tâm. Thoát bằng tổ hợp 4 nút |
| Calibrate J1/J2 | Thả cả hai cần về giữa, J1 SW lấy 64 mẫu và lưu; J2 SW hủy |
| Axis invert | Chọn J1X/J1Y/J2X/J2Y, SW đảo riêng từng trục |
| Deadzone | SW tăng từng bước 5%, vòng 5…40% |
| J2 mode | SW chuyển **Mouse pointer** / **Mapped keys** |
| Mouse speed | SW đổi 1…16 pixel/báo cáo ở độ lệch tối đa; tốc độ thực phụ thuộc host |
| System info | OS, tác giả, chip/revision, CPU, heap, flash, MAC STA, trạng thái sạc, OLED frames/s và lỗi I²C; L/R đổi trang, SW quay lại |
| UI motion | Bật/tắt hiệu ứng trang trí, lưu riêng vào Preferences; không ảnh hưởng mapping/calibration |
| Reset settings | Xác nhận Yes/No; đưa cài đặt về mặc định, không xóa bonding BLE |
| Restart | Xác nhận rồi khởi động lại |

Cài đặt lưu bằng Preferences. Chỉ hiệu chuẩn **tâm**, không tự đo hành trình min/max. ADC/deadzone/đảo chiều được áp dụng cho cả game và điều khiển ESP32 khác.

### Mapping mặc định

| Đầu vào | Action |
|---|---|
| JOY1 lên / trái / xuống / phải | W / A / S / D |
| JOY2 bốn hướng | Chuột mặc định; khi tắt mouse mode thì dùng phím mũi tên |
| BTN L | Left Shift |
| BTN R | Space |
| JOY1 SW | Enter |
| JOY2 SW | Escape |

Có lựa chọn chữ A–Z, 0–9, mũi tên, F1–F12, Space/Enter/Esc/Tab/Backspace/Delete, Home/End/PageUp/PageDown, Left Ctrl/Shift/Alt, chuột trái/phải/giữa hoặc None. Report dùng **HID usage**, không phải ký tự ASCII; chữ hiện ra còn phụ thuộc bố cục bàn phím hệ điều hành. Tối đa 6 phím thường đồng thời, cộng modifier.

Trong mouse mode, mapping bốn hướng JOY2 bị bỏ qua, mapping JOY2 SW vẫn có hiệu lực. Mapping này dành cho **HID**, không đổi các nút cố định của mini-game hoặc bit nút ESP-NOW. Cuộn chuột/macro/XInput chưa có giao diện gán trong bản này.

## 9. Các mini-game

Đây là **game tự viết**, hình học đơn sắc, lấy cảm hứng thể loại; không chứa ROM/ảnh/nhạc thương mại, không phải emulator NES/arcade và không phải bản sao nguyên gốc.

| Tên trong menu | Nhóm yêu cầu tương ứng | Điều khiển / mục tiêu |
|---|---|---|
| Maze Munch | Pac-Man / Ms. Pac-Man | JOY1, ăn hết chấm, tránh 3 địch; góc đặc biệt cho khả năng ăn địch tạm thời |
| Star Defenders | Space Invaders / Galaga | JOY1 ngang, giữ R bắn; nhiều đợt địch, 3 mạng |
| Pocket Platform | Mario-style | JOY1 ngang/cúi, L chạy/bắn, R nhảy; nhặt điểm, vượt hố đến cờ |
| Falling Blocks | Tetris-style | JOY1 ngang/xuống, L/R xoay, JOY1 SW thả cứng; 7 loại khối, xóa hàng |
| Tiny Flap | Flappy-style | Bấm R hoặc JOY1 SW để bay; vượt cột, tính điểm |
| Duo Pong | Pong / Air Hockey | JOY1 Y: vợt trái, JOY2 Y: vợt phải; 2 người, chạm 7 điểm thắng |
| Twin Arena | Smash TV-style | JOY1 di chuyển, JOY2 ngắm/bắn tự động khi lệch cần |
| Vector Storm | Geometry Wars-style | JOY1 di chuyển, JOY2 ngắm/bắn, R dùng 1 trong 3 bom |
| Micro Racer | Top-down Racing | JOY1 ngang, R tăng tốc, L phanh rồi lùi; tránh xe/vệ đường, đích 1200 |
| Snake | Snake | JOY1 đổi hướng, ăn mồi, tránh tường/thân |
| Mini Tanks | Tank 1990-style | JOY1 4 hướng, R bắn; gạch phá được, hạ 5 xe địch |

Sau Game Over/You Win: **R hoặc JOY1 SW chơi lại**. Thoát vẫn bằng giữ 4 nút 3 giây. Nhịp game là mô phỏng 20 ms mỗi tick, không phải bảo đảm 50 FPS trên OLED I²C.

## 10. Mở rộng điều khiển thiết bị thật

Trong `Receiver_Test.ino`:

```cpp
void onControl(const ctl::Packet &p) {
  // p.axis[0..3]: -1000..1000
  // p.buttons: B_L, B_R, B_J1, B_J2
  // Áp dụng PWM/servo/logic của THIẾT BỊ CỤ THỂ tại đây.
}

void stopOutputs() {
  // BẮT BUỘC đặt đầu ra thực về trạng thái an toàn:
  // PWM = 0, disable driver, nhả relay... tùy thiết bị.
}
```

Bản demo đã có các hàm này nhưng **chưa nối motor/relay/servo**. Không thêm `delay()` hoặc vòng lặp dài trong handler, vì sẽ làm hỏng timeout/ping. Với tải cảm/công suất cần driver, nguồn và bảo vệ phù hợp, không nối thẳng GPIO.

Đổi tên phát Wi-Fi ở `receiver.begin("espH_TenCuaBan", ...)`. Giữ tiền tố `espH_` và SSID không quá 32 byte. Không đổi tùy tiện kênh khi đang có peer ESP-NOW hoạt động.

### Các module để chỉnh sửa

- `Input.*`: pin, debounce 25 ms, lọc ADC, calibration, Preferences, bảng action HID.
- `ControllerLink.*`: scan, UDP handshake, peer ESP-NOW, ping/RTT.
- `BleOutput.*`: NimBLE HID, callback chỉ ghi cờ, main loop xử lý kết nối/quảng bá.
- `ChargeIndicator.h`: quy tắc blink icon nguồn.
- `USB_Bridge_S3/HidState.h`: trạng thái HID, đóng gói keyboard 8 byte/mouse 5 byte, xóa chuyển động cũ khi host không sẵn sàng.
- `Games.*`: logic và vẽ 11 mini-game OLED.
- `WebGames.*`, `WebAssets.h`: AP/router RAM-only, HTTP/WS, ghép PIN và tài nguyên gzip.
- `WebSetup.*`, `ConsoleInput.h`: wizard OLED chọn mạng, scan SSID, bàn phím/repeat JOY1, xác nhận điều hướng trước ghép PIN.
- `web/`: 26 game màu Canvas và giao diện trình duyệt; sửa nguồn trong `web/src/`, chạy `npm run web` rồi `python3 tools/embed_web.py`.
- `App.cpp`: state machine, giao diện, tổ hợp thoát và lịch logic/render riêng.
- `UiMotion.h`, `UiWidgets.*`: compositor, easing, icon, clipping/marquee.
- `OledPump.h`: SSD1306 truyền mỗi giao dịch 32 byte, không chờ toàn frame trong `display.display()`.
- `Protocol.h`: định dạng gói và mật khẩu/kênh dùng chung.
- `ReceiverLink.h`: discovery và bộ nhận ESP-NOW/failsafe dùng chung cho receiver/S3.

`Protocol.h` được chép vào cả 3 sketch để mở độc lập trong Arduino IDE; **sửa giao thức/mật khẩu thì sửa đồng bộ cả ba bản**. `ReceiverLink.h` ở hai sketch nhận cũng phải đồng bộ. Khi đổi layout gói, tăng VERSION và cập nhật `static_assert`.

## Web Games — vào nhanh

Home → Web Games → dùng **JOY1 / J1 SW** chọn **C3 Wi-Fi / direct** hoặc **Home Wi-Fi / router**. Wi-Fi nhà được quét/chọn và nhập mật khẩu bằng bàn phím OLED. **Không lưu router cho lần sau**; web2 xóa cấu hình router đã lưu của web1 khi mở Web Games.

Nếu AP: PC nối `ConTL_Play_XXXX`, mật khẩu `ESPConTL11` có trên OLED; mở **http://192.168.4.1/**. Nếu router: PC cùng LAN, mở LAN IP hiển thị trên OLED. Khi trang web kết nối, C3 hỏi **J2 cho phép bàn phím PIN**; JOY1/J1 SW nhập PIN OLED vào web. Chọn loại thiết bị trên web rồi nhập PIN. PIN đúng và socket được xác nhận: nền đen ngắn → nhấn đồng thời L+R → intro → thư viện. Fullscreen vẫn là nút tùy chọn, không có bước bắt buộc. Toàn bộ thư viện, game, pause, restart, back, settings điều khiển bằng controller.

Xem **`WEB5_HUONG_DAN.md`** cho nguồn điều khiển, rearm, OLED, fullscreen không bắt buộc và checklist. `WEB_CONSOLE_WEB2.md` là tài liệu lịch sử, luồng fullscreen web2 không còn áp dụng. `WEB_VA_SCAN_WEB1.md` là tài liệu lịch sử; chỉ phần discovery web1 vẫn áp dụng, không dùng luồng Wi-Fi/web cũ.

## 11. Checklist kiểm thử trên bàn

- [ ] C3 boot được khi tất cả ngoại vi cắm đủ; thử cả có/không cáp USB.
- [ ] OLED đúng địa chỉ/chiều, BTN L/R và hai SW nhận đúng.
- [ ] Hiệu chuẩn khi thả cần; kiểm tra bốn hướng; chỉnh Axis invert nếu cần.
- [ ] Kiểm tra điện áp CHRG/STDBY trước khi nối; so sánh C/F/-/! với module sạc thật.
- [ ] Bộ nhận xuất `espH_TestReceiver`, C3 quét/chọn/bắt tay được; không phải nhập MAC.
- [ ] Bốn trục/nút khớp Serial, RTT xuất hiện; đối chiếu C3 Serial để xem MAC/kênh peer.
- [ ] Rút nguồn C3 khi đang gửi lệnh: bộ nhận chuyển về trung tính và in STOP một lần. Với tải thật, thực sự đo xác nhận đầu ra đã về an toàn.
- [ ] Tắt/bật bộ nhận rồi quét lại; phiên cũ không được tiếp tục điều khiển.
- [ ] S3 được PC nhận là HID qua cổng native; thử phím/chuột ở cửa sổ test trống.
- [ ] Đang giữ phím rồi tắt C3: S3 nhả phím; thử khi PC sleep/wake và rút/cắm lại USB.
- [ ] BLE ghép đôi, nhả phím, mất kết nối, ghép lại; kiểm tra trên OS thực sự dùng.
- [ ] Chuyển lặp lại BLE → Home → ESP Remote → Home → USB để kiểm tra heap/radio thực tế.
- [ ] Chơi từng game; giữ tổ hợp 1–2 giây rồi thả hết để tiếp tục; giữ >3 giây để về Home.
- [ ] Settings còn sau reboot; Reset settings đưa về mặc định; peer ESP-NOW không tự được nhớ/kết nối lại.

## 12. Lỗi thường gặp

| Hiện tượng | Kiểm tra |
|---|---|
| Sketch too big | C3 cần Huge APP 3 MB, không để partition mặc định |
| Không thấy `espH_` | Bộ nhận đã nạp/cấp nguồn? SSID có đúng tiền tố? Thiết bị có phát AP 2.4 GHz? |
| Wi-Fi join timeout | Mật khẩu ba bên có khớp? AP chỉ nhận 1 client; ngắt client khác nếu có |
| Handshake timeout | Không chỉ đổi SSID trên firmware bất kỳ: phải có UDP/ESP-NOW receiver đúng protocol |
| Not a USB bridge | Vào USB via S3 thì chọn thiết bị nạp `USB_Bridge_S3`, không chọn receiver thường |
| ESP-NOW link lost | Khoảng cách/nhiễu/kênh; không cho STA bộ nhận nối router khiến kênh AP thay đổi |
| Không có USB HID | Đúng S3? USB Mode TinyUSB? Đúng cổng native, cáp có data, máy đích là host? |
| BLE thấy tên nhưng không nhập được | Host hỗ trợ BLE HID? Xóa pairing cũ và ghép lại; kiểm tra report/OS trên phần cứng |
| Cần trôi/ngược | Hiệu chuẩn ở giữa, tăng deadzone, Axis invert; kiểm tra nguồn 3.3 V và analog |
| Không vào bootloader | GPIO2/8/9 strapping, BOOT/SCL/OLED, thử tách ngoại vi khi nạp |
| OLED trắng/đen | Địa chỉ 0x3C, SSD1306 không phải SH1106, I²C8/9, nguồn/GND, setting invert |

## 13. Tái lập kiểm tra trên máy tính

Xem `verification/BUILD_AND_TEST.md`. `compile_all.sh` dùng Arduino CLI đã cài board/thư viện như trên. Linux có g++ có thể chạy `bash tests/run_host_tests.sh`.

Kiểm thử host chỉ kiểm tra logic với mock ngoại vi; **không chứng minh firmware đã chạy ổn trên thiết bị thật hoặc tương thích mọi PC/điện thoại**.
