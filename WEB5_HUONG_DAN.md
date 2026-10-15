# ESP ConTL v1.1 / web5 — HDZ463

Ngày 08/10/2026. Thêm 15 game **chỉ trên web**, chơi hai người trên cùng C3, giữ màn hình sáng, fullscreen tại PIN và logo/intro console mới.

> **Đang dùng đầy đủ web3 hoặc web4: chỉ nạp lại C3.** S3/Receiver_Test giữ nguyên bản sửa liên kết web3. Nếu từ web2/cũ hơn, cập nhật cả các bộ nhận đang dùng.
>
> **26 game web = 11 game cũ + 10 game một người mới + 5 game hai người mới. OLED vẫn đúng 11 game cũ.** Bộ lọc “2 người” có 6 mục vì giữ cả Duo Pong cũ.

## 1. Nạp và mở lại web

1. Giải nén toàn bộ ZIP, mở `SmartController_C3/SmartController_C3.ino` bằng Arduino IDE, không trộn các tab/file của bản cũ.
2. Dùng core **esp32 3.0.7**, ESP32C3 Dev Module, **USB CDC On Boot Enabled**, **Huge APP**, flash đúng board (bản đã build dùng 4 MB).
3. Thư viện chốt: **NimBLE-Arduino 2.3.6**, **WebSockets 2.6.1** (Links2004), **Adafruit SSD1306 2.5.13**, **GFX 1.11.11**, **BusIO 1.17.4**.
4. Web đã nhúng trong `WebAssets.h`: **không cần Node/Python/SPIFFS để nạp và dùng**.
5. Sau nạp, đóng trang cũ và mở lại đúng IP trên OLED; dùng **Ctrl+F5** nếu trình duyệt còn giữ assets cũ. Bản mới hiện `v1.1 / web5` ở footer.

Giữ pinmap CHRG4/STDBY5, J1 X0/Y1/SW10, J2 X3/Y2/SW6, L7/R20; OLED SDA8/SCL9/0x3C, 128×64, xoay 180°. ESP-NOW/USB/BLE, rearm và phục hồi OLED không đổi. Wi-Fi nhà vẫn **STA riêng, không tự đổi sang AP**, retry/edit/AP bằng lựa chọn trên OLED; mật khẩu RAM-only như web4.

## 2. Mười game một người mới — chỉ web

Các số nút dưới đây là nút vật lý C3 trong Web Games. R/SW1 ở bảng có nghĩa có thể dùng một trong hai nút.

| Game | Mục tiêu / luật chính | Điều khiển |
|---|---|---|
| **Prism Breaker** | Phá đủ 3 lớp gạch; bóng rơi mất mạng | JOY1 X điều khiển vợt, R thả bóng, giữ L mở rộng vợt |
| **Orbital Catch** | Thu 20 tín hiệu bằng khiên xoay, tránh bỏ lỡ | JOY1 X xoay; L xoay chậm; R khiên rộng tạm thời, có hồi chiêu |
| **Crosswalk** | Vượt các làn xe, về đích 3 lần | JOY1 đi theo ô; va xe mất mạng |
| **Color Dock** | Hứng 20 khối cùng màu với khay trong 90 giây | JOY1 X di chuyển; L/R đổi màu; hứng sai mất mạng |
| **Lunar Lander** | Đáp lên bệ với tốc độ ngang <25, tốc độ dọc <45 theo đơn vị game | JOY1 X đẩy ngang; R lực đẩy lên; L phanh. Có giới hạn nhiên liệu |
| **Mine Survey** | Mở đủ 68 ô an toàn trên bảng 80 ô/12 mìn | JOY1 chọn ô; R/SW1 mở; L cắm cờ. Ô mở đầu và vùng lân cận không có mìn |
| **Memory Circuit** | Ghép đủ 8 cặp ký hiệu | JOY1 chọn; R/SW1 lật; L xem nhanh, tối đa 2 lần |
| **Warehouse Grid** | Đẩy 3 thùng vào đích | JOY1 đi/đẩy; L hoàn tác; R làm lại. Không kéo thùng. Đã kiểm tra có lời giải hợp lệ 27 bước |
| **Bubble Harbor** | Ghép ít nhất 3 bóng cùng màu kề ngang/dọc; dọn sạch bảng | JOY1 X ngắm; R/SW1 bắn. Bóng không nối với trần rơi theo; 5 phát không ghép thêm một hàng |
| **Sky Courier** | Thả 8 kiện vào xe nhận trong 90 giây, tránh drone | JOY1 bay; R/SW1 thả hàng, có khoảng nghỉ giữa các lần thả |

Các game có điều kiện kết thúc, điểm số, chơi lại và menu; không phải chỉ thêm thẻ hoặc hình minh họa. Đây là mini-game tự viết, không phải ROM/game thương mại đầy đủ. Mức độ khó vẫn nên được bạn chơi thử và phản hồi.

## 3. Năm game hai người mới

Chơi **cùng một màn hình, cùng một C3**, không phải online multiplayer và không ghép hai C3.

| Người chơi | Di chuyển | Nút hành động | Nút phụ |
|---|---|---|---|
| **P1 / xanh** | JOY1 | **SW1** (J1 SW) | **L** |
| **P2 / cam** | JOY2 | **SW2** (J2 SW) | **R** |

| Game | Mục tiêu | SW1/SW2 | L/R tương ứng P1/P2 |
|---|---|---|---|
| **Paddle Clash** | Hockey hai nửa sân, ghi 5 bàn | Cú đánh mạnh ngắn | Mở rộng vợt tạm thời |
| **Arena Duel** | Đấu bắn, mỗi người 5 máu; ngắm theo hướng di chuyển gần nhất | Bắn | Khiên tạm thời, có hồi chiêu |
| **Coin Sprint** | Chạm 20 xu hoặc dẫn điểm sau 60 giây | Lướt nhanh | Xung đẩy đối thủ ở gần |
| **Trail Riders** | Tránh tường/vệt sáng của cả hai; thắng 3 vòng | Giữ để tăng tốc **xe của mình** | Nhảy qua đoạn vệt; tối đa 3 lần/vòng, có hồi chiêu |
| **Rescue Partners** | Phối hợp: mỗi người mang 3 kiện về bệ riêng; chung 3 mạng | Nhặt/thả kiện đang ở gần | Khiên tránh drone tạm thời |

- **SW2 không mở menu khi đang chơi game hai người.** Bit nút SW2 cũng không bị cắt khỏi dữ liệu game.
- Mở **Menu game** bằng **giữ riêng L + R khoảng 0,7 giây**, hoặc nút Menu trên màn hình / Esc ở bàn phím. L+R là tổ hợp dành riêng cho menu, không nên giữ đồng thời để dùng kỹ năng lâu.
- Khi menu đã mở, JOY1/J1 SW chọn; J2 SW quay lại/tiếp tục như giao diện chung.
- **Giữ cả L + R + SW1 + SW2 3 giây trên C3** vẫn dùng cơ chế pause/countdown/thoát Web Games về Home; không đổi firmware nút an toàn này.
- **Duo Pong cũ** vẫn là game hai người dùng hai trục Y. SW1/SW2 không thêm kỹ năng vào Pong, nhưng SW2 cũng không tự làm gián đoạn trận đấu.

### Chơi cục bộ trên máy tính

| P1 | P2 | Menu |
|---|---|---|
| WASD + **E = SW1**, **Q = L** | Mũi tên + **O = SW2**, **U = R** | Esc |

IJKL vẫn có thể điều khiển JOY2. Bàn phím có thể giới hạn số phím đồng thời (ghosting); dùng C3 nếu gặp mất phím khi hai người cùng bấm. Trên điện thoại/tablet, hai joystick cảm ứng và các nút được ghi P1/SW1, P2/SW2. Remote TV đơn lẻ không đủ hai bộ điều khiển: nên chọn nguồn C3; ở local TV, remote chỉ điều khiển P1 bằng mũi tên/OK.

## 4. Giữ màn hình sáng / tránh sleep

### Tự động trong trình duyệt khi chọn Máy tính

Có mục **Cài đặt → Giữ màn hình sáng**, mặc định bật cho profile Máy tính. Dùng API chuẩn **Screen Wake Lock**:

- Chỉ báo **“Wake Lock: đang bật”** sau khi trình duyệt thực sự cấp lock.
- Đổi tab/ẩn trang sẽ nhả lock theo quy định của trình duyệt; quay lại trang sẽ yêu cầu lại. Chuyển sang profile khác hoặc tắt tùy chọn cũng nhả lock.
- Nếu hệ điều hành thu hồi lock, trạng thái đổi rõ ràng; có nút **Thử lại Wake Lock**.
- Không giả bấm phím, không phát âm thanh/video ẩn để cố lách hạn chế trình duyệt.

**Giới hạn quan trọng:** trang C3 mặc định là `http://192.168...`, thường **không phải secure context**. Chrome/Edge và nhiều browser sẽ không cấp Wake Lock ở đây. Khi đó trang báo nguyên nhân; bật nút hoặc bật fullscreen không tự tạo quyền HTTPS. Browser có thể từ chối vì pin thấp, chính sách quyền, iframe hoặc hệ điều hành. API này không cho web sửa cài đặt Sleep/khóa máy của OS và không bảo đảm mọi PC luôn thức.

Người triển khai nâng cao có thể dùng HTTPS reverse proxy tin cậy: proxy HTTP về C3:80 và nâng cấp WebSocket `/pair`, `/socket` về C3:81. Web5 tự chọn WSS/cùng host khi được phục vụ qua HTTPS. **Bộ này không triển khai TLS/proxy/chứng chỉ trên C3**, nhánh proxy chưa thử tích hợp trên mạng thật. Không mở C3 ra Internet chỉ để có HTTPS.

### Cách dùng với HTTP C3 trên Windows

Có helper **tùy chọn**, không tự chạy: `tools/Keep-Awake-Windows.ps1`.

1. Mở PowerShell trong thư mục đã giải nén.
2. Chạy:
   ```powershell
   powershell -NoProfile -File .\tools\Keep-Awake-Windows.ps1
   ```
3. Để cửa sổ đó mở trong lúc chơi. **Nhấn Ctrl+C khi chơi xong.** Đóng trang web không tự dừng helper.

Helper gọi Windows `SetThreadExecutionState` để yêu cầu giữ màn hình/hệ thống thức trong thời gian chạy. Không sửa registry, power plan hoặc tạo startup task. Yêu cầu được nhả khi dừng; chính sách OS/doanh nghiệp, screensaver/khóa máy hoặc gập nắp máy vẫn có thể can thiệp. Có thể tăng tiêu thụ pin. **Mã helper mới chỉ được rà soát, chưa chạy thử trên Windows thật trong môi trường này.** Trạng thái Wake Lock trên trang chỉ phản ánh API của browser, không đo trạng thái của helper.

Nếu Windows chặn script theo execution policy, **không cần tắt chính sách bảo mật**: dùng **Settings → System → Power & battery → Screen/Sleep** (tên mục tùy Windows), tạm thời không tắt màn hình/sleep khi đang chơi rồi khôi phục sau đó. macOS có thể dùng `caffeinate -di` trong Terminal và Ctrl+C để dừng; Linux dùng cài đặt Power của desktop. Những phương án OS là thao tác thủ công, không do trang web tự bật.

## 5. Fullscreen ngay ở màn PIN

- Nút **⛶ Toàn màn hình** nằm bên phần hướng dẫn ghép PIN, dùng được **trước khi nhập xong PIN**.
- Bật/tắt fullscreen không xóa số đã nhập, không tự xác thực hoặc đổi sang thư viện.
- Hành động từ C3 qua WebSocket có thể không được browser coi là user activation. Nếu bị chặn, nhấp nút bằng chuột/chạm/phím hoặc remote trực tiếp trên thiết bị. Không bắt buộc fullscreen để nhập PIN hay chơi.
- Thiếu API, reject hoặc Promise không trả kết quả vẫn không khóa giao diện. Giữ bố cục vừa viewport của web4.

## 6. Logo, intro và chuyển động TV

- Logo **tay cầm ESP ConTL** dạng SVG tự vẽ, có D-pad, hai cần, nút và dải sáng; không tải ảnh/font ngoài Internet.
- Logo nhỏ ở header và logo intro cùng nhận diện.
- Luồng vẫn là **PIN → nền đen ngắn → L+R / Enter / Bắt đầu → intro → thư viện**.
- Intro mới khoảng **2,7 giây**: thân tay cầm xuất hiện, các cụm nút ghép vào, dải sáng bật, tên ESP ConTL/HDZ463 hiện rồi chuyển cảnh.
- TV có animation intro, chuyển trang, focus/thẻ game và ánh nền nhẹ. Không còn tắt ambient riêng cho TV. Chủ yếu dùng opacity/transform, không bật lại blur nặng trên TV.
- Tôn trọng **prefers-reduced-motion**: nếu hệ điều hành/browser yêu cầu giảm chuyển động, animation được giảm/tắt. Đây là lựa chọn trợ năng, không phải lỗi thiếu hiệu ứng.

## 7. Kiểm thử và giới hạn

Đã có kiểm thử phần mềm, không có board/TV/PC Windows thật gắn với môi trường này:

- 26 game web × 30.000 tick = **780.000 tick**; focused tests cho thắng/thua, an toàn click đầu Mine Survey, Warehouse có lời giải, từng trục/nút hai người, turbo độc lập và cứu hộ phối hợp.
- 11 game OLED và host logic cũ giữ nguyên; không thêm game vào firmware OLED.
- Browser mock đi qua cả 26 game, PIN/intro/menu/restart, nguồn input độc lập, stale pause, cảm ứng/TV keycodes.
- Fullscreen gốc Chromium tại màn PIN giữ nội dung đang nhập; bố cục 5 kích thước từ 1280×560 đến 1920×1080 (có 1024×600).
- Wake Lock **mock** kiểm tra cấp/từ chối/không hỗ trợ/HTTP/ẩn trang/quay lại/thu hồi/tắt và Promise trả về muộn. **Không phải đo máy tính có ngủ thật hay không.**
- TV animation và reduced-motion qua Chromium profile; chưa chứng minh FPS/khả năng GPU của TV thực tế.

Log, số liệu build, checksum trong `verification/`. Khi thử thật, nên kiểm tra riêng SW2 không mở menu, giữ L+R mở menu, bốn nút 3 giây thoát, hai người bấm đồng thời, fullscreen trên TV và khả năng giữ màn hình sáng của PC.

## 8. Phát triển / preview

Chỉ dành cho sửa nguồn, không cần để nạp Arduino:

```sh
npm ci
npm run web
python3 tools/embed_web.py
bash tests/run_host_tests.sh
node tests/web_games_test.js
node tests/extra_games_test.js
python3 tools/preview.py --port 5175
# Terminal khác, cần Playwright + Chromium:
python3 tests/browser_test.py
python3 tests/features_web5_test.py
python3 tests/layout_web5_test.py
# Cần arduino-cli/core/libs:
bash compile_all.sh
```

`web/src/extra_games.js` chứa 15 game web mới; builder gộp vào `web/games.js`. `web/src/wake_lock.js` được gộp vào `web/app.js`. HTML/compat chỉnh trực tiếp; JS/CSS khác sửa trong `web/src/`. Sau đó build web + embed để cập nhật firmware. Không sửa riêng file sinh.

Preview `http://localhost:5175/?demo=1` chơi cục bộ, không giả lập RF/board. Các tài liệu WEB4/WEB3/WEB2 trong bộ là lịch sử; ưu tiên hướng dẫn web5 này cho số game, điều khiển hai người, intro và chống sleep.
