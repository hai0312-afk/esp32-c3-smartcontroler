> **TÀI LIỆU LỊCH SỬ WEB2.** Với bản đang đóng gói, đọc `WEB3_HUONG_DAN.md` và `README_VI.md`. Web3 phải nạp cả C3 và bộ nhận, thêm chọn thiết bị và vào thư viện ngay sau PIN; các bước fullscreen gate, chỉ nạp C3 và số liệu build web2 bên dưới không áp dụng cho web3.

# ESP ConTL v1.1-web2 — Web Console / HDZ463

**Bản web2 đổi luồng Web Games theo yêu cầu: chọn mạng trên tay cầm, JOY1 nhập mật khẩu OLED, PIN hiện trên C3 và nhập ở web bằng controller, giao diện console có focus và menu điều khiển đầy đủ.** Tên OS vẫn ESP ConTL v1.1.

> Nếu đang chạy **web1**, chỉ cần nạp lại **C3**. S3/Receiver_Test và phần discovery giữ nguyên web1. Nếu đi từ UI1/fix1/bản gốc, nạp cả C3 và S3/receiver để có discovery web1.
>
> Đã biên dịch và kiểm thử logic/browser trên PC; **chưa thử trên board C3/S3 thật**. Các ảnh trong `verification/` là browser demo, không phải chứng cứ radio/hardware.

## 1. Cài / nạp

Giải nén vào thư mục mới. Arduino IDE mở `SmartController_C3/SmartController_C3.ino`; giữ toàn bộ `.h/.cpp` đi kèm. Không trộn các tab web cũ.

- Board **ESP32C3 Dev Module**, flash đúng phần cứng (thường 4 MB), **Huge APP**, **USB CDC On Boot = Enabled**.
- Core **esp32 by Espressif Systems 3.0.7**.
- Library Manager: **WebSockets 2.6.1** (Markus Sattler / Links2004), **NimBLE-Arduino 2.3.6**, **Adafruit SSD1306 2.5.13**, **Adafruit GFX Library 1.11.11**, **Adafruit BusIO 1.17.4**.
- WebServer/WiFi/Preferences/USB nằm trong core.
- `WebAssets.h` đã có sẵn: **không upload LittleFS/SPIFFS**, không cần Python/Node để nạp bằng IDE. Sau khi nạp, tải lại trang web bằng Ctrl+F5 nếu PC còn giao diện cũ.

GPIO, OLED 128×64 địa chỉ 0x3C xoay 180°, mapping/calibration, BLE, USB via S3, 11 game OLED và UI motion được giữ.

## 2. Luồng sử dụng mới

```text
Home → Web Games
       ├─ C3 Wi-Fi / direct ────────────────┐
       └─ Home Wi-Fi / router              │
           → quét SSID                     │
           → JOY1 chọn mạng                │
           → bàn phím OLED nhập pass → OK  │
                                          ↓
                    OLED hiện IP / Wi-Fi / mật khẩu / PIN
                                          ↓
                    PC nối mạng phù hợp, mở http://<IP>/
                                          ↓
                    OLED: J2 SW cho phép bàn phím PIN
                                          ↓
                    JOY1 chọn số trên web, J1 SW nhập
                    PIN đúng → màn hình yêu cầu fullscreen
                                          ↓
                    1 lần nhấp PC / F11 → giao diện console
```

### C3 tự phát Wi-Fi

1. Home → Web Games. C3 **chưa tự chọn phương thức**, màn hình đầu hỏi **C3 Wi-Fi / direct** hoặc **Home Wi-Fi / router**.
2. JOY1 di chuyển, **JOY1 SW chọn**. Chọn C3 Wi-Fi.
3. PC nối **`ConTL_Play_XXXX`**. Mật khẩu AP **`ESPConTL11`**, cũng hiện trên OLED ở dòng **PW:**.
4. Mở **http://192.168.4.1/**. Chấp nhận mạng không có Internet. Dùng HTTP, không HTTPS.

### Wi-Fi nhà — chọn và nhập mỗi lần

1. Chọn **Home Wi-Fi / router**. C3 quét các SSID 2.4 GHz đang hiện; tối đa 24 tên, ưu tiên sóng mạnh. `*` là mạng có bảo vệ, `o` là mạng mở.
2. **JOY1** lên/xuống (hoặc trái/phải) duyệt; **J1 SW** chọn; **J2 SW** quay lại. Có **Scan again** ở cuối.
3. Bàn phím OLED xuất hiện. Nhập mật khẩu rồi chọn **OK**.
4. OLED hiện trạng thái nối router. Khi thành công, thông tin **AP / LAN** luân phiên mỗi 5 giây. PC ở cùng LAN mở **http://<LAN IP trên OLED>/**.
5. Mật khẩu đang gõ hiện trực tiếp trên OLED. Sau khi nối, khi trang **LAN** đang hiện, **giữ R** để xem lại mật khẩu router; chuỗi dài cuộn qua dòng PW. Buông R để ẩn. Trang AP luôn hiện mật khẩu AP. Chú ý người đứng cạnh khi nhập/xem mật khẩu.

**Không lưu SSID/mật khẩu router cho lần sau:** chỉ giữ RAM trong phiên Web Games để duy trì kết nối/retry. Thoát bằng tổ hợp 4 nút hoặc reset sẽ cần chọn/nhập lại. Firmware đặt Wi-Fi storage RAM. Khi mở Web Games lần đầu ở web2, các key router/ssid/pass của web1 trong `contl_web` được xóa ở mức Preferences; không thay mapping/calibration. Đây không phải cam kết xóa pháp chứng mọi byte flash cũ.

- Khuyến nghị WPA2-Personal 2.4 GHz, mật khẩu **8–63 ký tự ASCII**. Mạng mở: để trống và OK. Không có nhập Unicode cho mật khẩu, SSID ẩn/manual, Enterprise hoặc captive portal trong bàn phím OLED này.
- PC có thể ở Ethernet hoặc Wi-Fi 5 GHz nếu chung LAN với C3; không bật guest/client isolation. Cho phép TCP 80/81 trong LAN, **không mở cổng ra Internet**.
- Router lỗi/sai pass: sau **15 giây** C3 về **AP fallback**. PC có thể nối AP và chơi; muốn nhập lại mạng thì giữ 4 nút 3 giây về Home, mở lại Web Games.
- Nếu router dùng 192.168.4.x, AP chuyển sang **10.42.0.1** như web1; đọc IP thực tế trên OLED. Mạng/VPN/subnet đặc biệt không nằm trong xử lý tự động này.

## 3. Bàn phím mật khẩu trên OLED

Bàn phím **10 cột × 4 hàng**, focus trắng, điều khiển bằng JOY1. Trục dùng calibration/invert sẵn có. Nếu hướng ngược, chỉnh Settings → Axis invert trước.

| Điều khiển | Tác dụng |
|---|---|
| JOY1 bốn hướng | Di chuyển ô, giữ cần để lặp sau 380 ms, rồi mỗi 125 ms |
| J1 SW | Nhập ô đang chọn |
| L hoặc ô `<` | Xóa ký tự cuối |
| R hoặc ô `Aa` | Chuyển 3 trang: chữ thường + số → chữ hoa + số → ký hiệu |
| Ô `SP` | Dấu cách |
| Ô `OK` | Kiểm tra độ dài và kết nối |
| J2 SW | Hủy mật khẩu, quay lại danh sách mạng |
| Giữ 4 nút 3 giây | Hủy toàn bộ và về Home |

Có đủ ký tự ASCII in được, gồm dấu cách, dấu nháy, backslash, backtick… Giới hạn 63 byte, không thêm được ký tự thứ 64. Dòng PW hiển thị phần cuối khi chuỗi dài; khi đang chỉnh mật khẩu không có cursor chèn giữa, dùng xóa cuối để sửa.

## 4. Ghép PIN bằng controller — PIN vẫn nằm trên C3

Bạn đã chọn chiều **C3 hiện PIN → nhập trên trang web**, không phải trang web hiện mã để nhập vào C3.

1. Khi web mở được kết nối đến C3, OLED hiện **`J2: allow PIN keypad`**.
2. Nhấn **J2 SW** một lần và thả. Đây là xác nhận vật lý để cấp một kênh điều hướng hạn chế cho trang chưa ghép.
3. Nhìn **PIN 6 số trên OLED**, dùng **JOY1** chọn các số ở bàn phím web, **J1 SW** nhập từng số. **J2 SW** hoặc ô ⌫ xóa. **R** hoặc ô **Ghép** gửi PIN.
4. Sai mã: web báo lỗi, xóa các số đã nhập để thử lại. Sau 8 lần sai trong cửa sổ 30 giây, phải chờ hết giới hạn.
5. Đúng PIN: mở phiên điều khiển đầy đủ, chuyển sang yêu cầu fullscreen. Token giữ trong sessionStorage của tab; tải lại tab ở cùng địa chỉ trong cùng phiên C3 có thể nối lại mà không gõ PIN lần nữa. Mỗi lần C3 vào Web Games có PIN/token mới.

**Vì sao thêm J2 xác nhận?** Nếu chỉ cho gửi đầu vào sau khi ghép thì không thể dùng controller để gõ PIN. Kênh trước ghép chỉ gửi hướng JOY1 dạng rời rạc và nút điều hướng **sau khi người dùng nhấn J2 trên C3**, không tự gửi PIN/token/mật khẩu/raw axes đầy đủ. Sau khi ghép nó được đóng. Phiên chờ PIN hết hạn sau 120 giây; web tự xin lại, cần J2 cho phép lại. Không xác nhận yêu cầu lạ từ một PC bạn không mở trang.

Web2 dùng **một trình duyệt điều khiển tại một thời điểm**, tránh hai tab cùng nhận input và thao tác song song. Đóng tab cũ hoặc dùng **Cài đặt → Ngắt ghép trang web** để đổi sang trang khác. Web tại AP IP và LAN IP là hai origin khác nhau; có thể cần ghép lại khi chuyển IP.

## 5. Toàn màn hình: giới hạn bắt buộc của trình duyệt

Sau ghép có màn hình **Bật toàn màn hình**. Bấm trực tiếp nút này trên PC **một lần**; từ đó duyệt/chơi/menu dùng controller. Nó mở toàn màn hình cả giao diện, không chỉ canvas game.

- Sự kiện đến từ WebSocket **không phải user activation của trình duyệt**, nên không bảo đảm dùng J1 SW tự mở fullscreen. Khi bị chặn, web giải thích rõ, không giả vờ đã bật.
- Có thể nhấn **F11** (hoặc phím toàn màn hình tương ứng trên PC), rồi dùng JOY1/J1 SW chọn **Tôi đã bật bằng F11**. Web không giả định rằng F11 đã được phát hiện bằng Fullscreen API.
- Có tùy chọn **Tiếp tục ở chế độ cửa sổ**, để không bị kẹt nếu PC/iframe không cho fullscreen.
- Âm thanh cũng tuân theo chính sách autoplay: cú nhấp/phím PC đầu tiên sẽ mở quyền âm thanh khi trình duyệt cho phép. Nếu chưa có, Cài đặt báo cần một thao tác PC. Không âm thanh vẫn chơi được.

Không cần cài ứng dụng PC, không giả lập chuột hệ điều hành để lách giới hạn trình duyệt. Web Games không cần S3.

## 6. Điều khiển toàn bộ giao diện console

Giao diện mới dùng spotlight game, dãy thẻ ngang, focus sáng theo màu game, điều hướng không cần chuột và menu tạm dừng. Đây là giao diện console tự thiết kế, không phải firmware/SDK PS5 hoặc Xbox, không phải gamepad XInput.

| Nơi / nút | Chức năng |
|---|---|
| JOY1 ở giao diện | Di chuyển focus theo không gian: ô game, tab, nút, cài đặt, hộp xác nhận |
| J1 SW | Chọn/xác nhận nút đang focus |
| J2 SW trong thư viện | Mở Cài đặt |
| L/R trong thư viện | Đổi nhóm Tất cả / Cổ điển / Hành động / Thư giãn |
| J2 SW trong game | Tạm dừng/mở menu; nhấn lại để tiếp tục khi có tín hiệu |
| Menu tạm dừng | Tiếp tục / Chơi lại / Về thư viện / Cài đặt |
| Chơi lại, về thư viện, ngắt ghép | Có hộp xác nhận, mặc định **Hủy** |
| J2 SW trong cài đặt/hộp xác nhận | Quay lại/hủy |
| Giữ L + R + J1 SW + J2 SW | Neutral/pause ngay; giữ đủ 3 giây về Home trên C3; thả hết trước 3 giây tiếp tục |

Cài đặt có âm thanh, fullscreen, thông tin AP/LAN/RTT, hướng dẫn đổi Wi-Fi bằng OLED, ngắt ghép và quay lại. Đổi mạng là thao tác **trên controller**, không có form mật khẩu router trên web nữa. API `/api/wifi` cũ trả 405.

Khi chơi, JOY1/JOY2/L/R/J1 SW giữ chức năng game như web1. **J2 SW được dành cho menu**. 11 game vẫn là Maze Munch, Star Defenders, Pocket Platform, Falling Blocks, Tiny Flap, Duo Pong, Twin Arena, Vector Storm, Micro Racer, Garden Snake, Mini Tanks. Pong dùng hai trục Y trên cùng C3. Không phải multiplayer mạng.

Mất input >400 ms/game mất socket: dừng mô phỏng. Khi có gói mới có thể tiếp tục nếu không đang pause thủ công. Mất focus/chuyển tab: tạm dừng thủ công, cần Tiếp tục. Không tự chạy bù thời gian bị dừng. Các cạnh nhấn nút nhận từ WebSocket được giữ đến frame xử lý, tránh bỏ sót khi render chậm hơn gói đến.

Kỷ lục lưu localStorage theo trình duyệt/origin; thư viện mới không có sidebar “game gần đây” của web1. Toàn bộ tài nguyên vẫn offline, không CDN/ROM.

## 7. Xem thử trên PC

`python3 tools/preview.py` → `http://127.0.0.1:5173/`, hoặc mở `web/index.html`. Live preview đi kèm cũng là **DEMO bàn phím**, không kết nối C3.

- Giao diện: mũi tên/WASD = JOY1; Enter = J1 SW; Esc = J2 SW; Shift/Space = L/R. Có Tab/Shift+Tab và chuột như phương án phụ.
- Game: WASD/mũi tên = JOY1, IJKL = JOY2, Shift = L, Space = R, Enter = J1 SW, Esc = menu. Pong: W/S vợt trái, ↑/↓ vợt phải.
- Demo bắt đầu ở yêu cầu fullscreen, không mô phỏng một C3 đã ghép. Test PIN/controller trong test tự động dùng WebSocket giả lập, tách khỏi demo.

## 8. Kiểm thử và an toàn

Xem `verification/BUILD_AND_TEST.md`. Đã build 4 cấu hình, host ASan/UBSan, 330.000 tick game OLED + 330.000 tick game web, bàn phím OLED/repeat/bounds và Chromium với toàn bộ 11 game/menu/PIN qua input giả lập.

**Chưa đo trên board thật:** OLED keyboard + joystick thực, quét/join router, RSSI, heap runtime/chuyển mode, AP fallback, PIN/WebSocket server và latency/FPS. 25 ms input / bước mô phỏng 1/60 s / lịch OLED 33–80 ms là mục tiêu phần mềm, không phải benchmark phần cứng.

HTTP/WS vẫn không TLS. Chỉ dùng mạng riêng tin cậy; PIN không bảo vệ khỏi người chặn bắt lưu lượng trên LAN đã bị xâm nhập. Không log PIN/mật khẩu, không trả chúng trong `/api/status`. AP vẫn dùng mật khẩu demo cố định. Firmware receiver vẫn là demo, không dùng điều khiển tải nguy hiểm.

### Checklist sau nạp

- [ ] Vào Web Games luôn hỏi phương thức, không tự nối Wi-Fi cũ.
- [ ] AP: OLED hiện SSID/PW/IP/PIN; PC vào web và C3 hiện yêu cầu J2.
- [ ] Router: chọn SSID, thử chữ hoa/thường/số/ký hiệu/dấu cách/xóa; OK nối đúng.
- [ ] Thử sai pass → AP fallback; giữ 4 nút về Home → phải nhập lại mạng.
- [ ] PIN sai/đúng; J2 cho phép, thả hết nút không tự nhập số; không gửi PIN tự động.
- [ ] Fullscreen bằng nhấp PC/F11, sau đó toàn bộ menu bằng JOY1/J1/J2/L/R.
- [ ] Chơi, pause, restart, hủy xác nhận, quay về, settings, mất Wi-Fi và vào lại.
- [ ] Ra/vào Web Games 10 lần, reset C3, kiểm tra PIN mới và router không tự nhớ.
- [ ] BLE/USB via S3/Remote/OLED games vẫn hoạt động khi đổi chế độ.
