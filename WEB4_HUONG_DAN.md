> **LỊCH SỬ WEB4.** Bản hiện tại là web5: đọc `WEB5_HUONG_DAN.md`. Web có 26 game, 5 game hai người mới, Wake Lock có giới hạn HTTP, fullscreen ở PIN và intro 2,7 giây/logo console mới.

# ESP ConTL v1.1 / web4 — HDZ463

Bản cập nhật theo phản hồi: Wi-Fi nhà, giao diện vừa màn hình máy tính, nhãn văn bản và intro sau PIN. Ngày 07/10/2026.

## 1. Cần nạp gì?

**Nếu đã nạp đầy đủ web3: chỉ cần nạp lại C3.** S3 và Receiver_Test được giữ nguyên từ web3, vẫn có trong bộ này. Nếu đang ở web2 hoặc cũ hơn, nạp cả C3 và các bộ nhận bạn sử dụng để có sửa lỗi liên kết của web3.

- Mở `SmartController_C3/SmartController_C3.ino` bằng Arduino IDE; giữ tất cả `.h`/`.cpp` cùng thư mục.
- Core **esp32 3.0.7**, board **ESP32C3 Dev Module**, **CDC On Boot Enabled**, **Huge APP**, flash đúng board (cấu hình đã build: 4 MB).
- Thư viện: **NimBLE-Arduino 2.3.6**, **WebSockets 2.6.1** (Links2004), **Adafruit SSD1306 2.5.13**, **GFX 1.11.11**, **BusIO 1.17.4**.
- Web đã nhúng trong `WebAssets.h`. Không cần Node, Python hoặc upload SPIFFS để sử dụng.
- Sau nạp, đóng trang web cũ rồi mở lại IP trên OLED. Nếu vẫn thấy giao diện cũ, dùng Ctrl+F5 hoặc xóa dữ liệu trang cho IP đó.

Pinmap, OS v1.1/HDZ463, 11 game, BLE, USB qua S3, rearm/failsafe và khôi phục OLED của web3 được giữ lại. Đấu nối/cấu hình board chi tiết: `README_VI.md`.

## 2. Wi-Fi nhà: không tự chuyển sang AP

### Điều đã thay đổi

Web3 luôn tạo AP trước, dùng AP+STA khi nối router, luân phiên hiển thị AP/LAN trên OLED và fallback sang AP sau 15 giây. Vì vậy, chỉ nhìn thấy SSID/IP của C3 **chưa đủ kết luận router đã thất bại**.

Web4 tách rõ:

| Bạn chọn trên OLED | Radio và thông tin hiển thị |
|---|---|
| C3 Wi-Fi / direct | AP của C3, SSID `ConTL_Play_XXXX`, pass `ESPConTL11`, `http://192.168.4.1/`. |
| Home Wi-Fi / router | **Chỉ STA**, không tạo AP song song. Khi nối thành công và có IP: OLED luôn hiện tên Wi-Fi nhà + **LAN IP**, không đổi qua lại với AP. |

Bước nối router:
1. Chọn Home Wi-Fi, quét/chọn mạng **2.4 GHz**, nhập mật khẩu trên OLED bằng JOY1/J1 SW như trước. Chọn OK.
2. OLED hiển thị `JOINING HOME WI-FI`, tên mạng, số lần thử và thời gian.
3. Có tối đa **2 lần thử × 25 giây**, nghỉ 1 giây giữa hai lần. Chỉ báo sẵn sàng khi đã kết nối **và có IP khác 0.0.0.0**. Nếu mạng tốt, không cần chờ hết thời gian này.
4. Trong lúc nối, **J2** hủy và quay về sửa mật khẩu.
5. Nếu vẫn không được: `HOME WI-FI FAILED` cùng mã disconnect gần nhất. Bạn chọn:
   - **J1:** thử lại cùng SSID/pass đang giữ trong RAM.
   - **J2:** sửa mật khẩu, giữ nội dung đã nhập để chỉnh. Từ bàn phím mật khẩu có thể J2 về danh sách mạng.
   - **R:** chủ động chuyển sang C3 Wi-Fi/AP.

**Không tự fallback sang AP.** Nếu đang dùng LAN rồi mất kết nối, firmware thử nối lại cùng mạng theo chính sách trên; nếu thất bại thì chờ bạn lựa chọn. Trong lúc mất stream, game trên web vẫn dừng an toàn.

Thiết bị mở web phải cùng LAN. PC/TV có thể dùng Ethernet hoặc Wi-Fi 5 GHz nếu router nối chung LAN với C3 2.4 GHz. Tránh guest/client isolation, nhập đúng `http://<LAN-IP-trên-OLED>/`, không dùng địa chỉ AP khi chọn Home Wi-Fi. Mật khẩu chỉ giữ RAM của phiên; mở lại Web Games vẫn hỏi cách nối mạng và nhập lại, không lưu router cho lần sau.

### Nếu router vẫn không nối

Đã sửa luồng mạng và thêm chẩn đoán; **chưa thử trên router của bạn**, nên không khẳng định mật khẩu/chuẩn bảo mật/DHCP/sóng đã hoạt động thực tế.

Mở Serial Monitor C3 **115200**, gửi log `[WEB-WIFI]` từ trước khi nhập xong đến lúc thất bại, kèm dòng trên OLED. Log ghi attempt, status, disconnect reason, LAN IP/kênh/RSSI khi thành công; không ghi mật khẩu/PIN. Mã reason có thể gồm cả lần ngắt chủ động khi đổi mode/thử lại, cần đọc toàn chuỗi thời điểm, không chẩn đoán chỉ từ một mã. Nếu cần, thử SSID 2.4 GHz riêng với WPA2-Personal để khoanh vùng; không cần bỏ mật khẩu bảo vệ mạng.

## 3. Giao diện máy tính/fullscreen

- Màn chọn thiết bị, PIN, thư viện và trang chơi của profile **Máy tính/TV** được bố trí theo chiều cao viewport: header → nội dung → footer, không cộng thêm chiều cao trang dư phía dưới.
- Hero, dãy thẻ, chữ và khoảng cách co lại trên màn hình thấp. Dãy game vẫn **cuộn ngang** để chọn đủ 11 game; đây là chủ ý, không phải lỗi cuộn dọc.
- Canvas dùng `object-fit: contain`: giữ toàn bộ khung hình trò chơi, không kéo méo hoặc cắt game để lấp màn hình. Có thể có khoảng đen ở hai bên/trên dưới tùy tỷ lệ màn hình.
- Đã kiểm tra trình duyệt ở **1920×1080, 1366×768, 1280×720, 1024×600 và 1280×560**. Kiểm tra cả kích thước nội dung bên trong, không chỉ giấu scrollbar.
- Chế độ vừa khung áp dụng khi profile PC/TV có viewport ít nhất **800×560 CSS px**. Ở cửa sổ rất nhỏ/zoom chữ lớn và profile điện thoại/tablet, vẫn cho cuộn tự nhiên để tránh cắt mất nút. Hộp Cài đặt có thể cuộn riêng khi cần.
- **Fullscreen vẫn tùy chọn**, không bắt buộc để vào thư viện hoặc chạy intro. Trình duyệt thiếu/từ chối/không trả kết quả Fullscreen API không làm khóa trang.

Nhãn văn bản đã đổi sang rõ chức năng: **“Nghỉ một nhịp” → “Menu game”**, nút **“J2 SW / Menu game”**, phần ghép PIN là **“Ghép nối tay cầm C3”**, chọn thiết bị là **“Chọn thiết bị để bắt đầu”**. Hướng dẫn bàn phím không còn ghi “Demo” khi người dùng chủ động chơi cục bộ trên bản thật.

## 4. Luồng mới sau PIN

```text
PIN đúng + socket xác nhận
  → nền đen khoảng 0,65 giây
  → hiện gợi ý L + R trên nền đen
  → nhấn đồng thời L + R
  → intro ESP ConTL / v1.1 / HDZ463 khoảng 1,9 giây
  → thư viện game
```

- **Thả nút R dùng gửi PIN trước**, rồi nhấn đồng thời L và R. Nút đang giữ từ bước trước không tự kích hoạt intro. Nhấn riêng L hoặc R không chạy intro.
- Sau intro, thả L/R để bắt đầu điều hướng; tổ hợp này không được dùng nhầm để đổi bộ lọc thư viện.
- Có **Enter / nút Bắt đầu** trên màn hình cho PC, remote hoặc cảm ứng. Chơi cục bộ bằng bàn phím cũng có thể nhấn **Shift + Space** tương ứng L + R.
- Bản preview và lựa chọn chơi cục bộ không cần PIN nhưng vẫn có intro để xem thử.
- Không yêu cầu âm thanh tự phát hoặc Fullscreen API; hỗ trợ chế độ giảm chuyển động của trình duyệt.
- Intro không chạy lại chỉ vì đổi fullscreen, đổi kích thước cửa sổ hoặc socket tự nối lại trong khi đã ở thư viện/game. Một lần ghép PIN mới sẽ chạy lại luồng.

## 5. Thử nhanh sau khi nạp

1. Home Wi-Fi: nhập pass đúng → tên Wi-Fi nhà/LAN IP giữ cố định, không thấy C3 phát AP của Web Games. PC cùng LAN mở đúng IP.
2. Thử pass sai: chờ hết hai lượt → báo thất bại, **không tự có AP**. J2 sửa pass rồi thử lại; sau đó thử lựa chọn R dùng AP riêng.
3. Thoát Web Games/vào lại: vẫn hỏi mạng, không nhớ router/pass cho phiên mới.
4. Nhập PIN bằng C3, thả R → màn đen ngắn → nhấn L+R → intro → thư viện. Thử chỉ L hoặc chỉ R trước để xác nhận không vào nhầm.
5. Chọn Máy tính, bật/tắt fullscreen. Xem đủ tiêu đề, nút chơi, dãy game, footer; vào game và mở **Menu game**. Không cần con lăn dọc ở kích thước đã hỗ trợ.
6. Tắt Wi-Fi/router khi chơi: game phải dừng khi input cũ; C3 không tự đổi AP. Kiểm tra OLED/log để thử lại hoặc đổi mạng.

**Tình trạng kiểm chứng:** có build firmware, host tests và Chromium/mock. Không có board, router, màn OLED hay TV thật trong môi trường kiểm thử. Xem `verification/BUILD_AND_TEST.md` để phân biệt phép thử đã chạy với checklist thực tế.

## 6. Sửa nguồn và xem thử

Không cần làm bước này nếu chỉ nạp bằng Arduino IDE:

```sh
npm ci
npm run web
python3 tools/embed_web.py
bash tests/run_host_tests.sh
node tests/web_games_test.js
python3 tools/preview.py --port 5174
# Terminal khác, cần Playwright + Chromium:
python3 tests/browser_test.py
python3 tests/layout_web4_test.py
# Cần arduino-cli/core/libs:
bash compile_all.sh
```

Nguồn web: `web/src/`; HTML và compat sửa ở `web/index.html`, `web/compat.js`. Sau sửa cần build và embed lại. Preview `http://localhost:5174/?demo=1` không có ESP/RF thật.

`WEB3_HUONG_DAN.md`, `WEB_CONSOLE_WEB2.md`, `WEB_VA_SCAN_WEB1.md` là lịch sử; luồng mạng/fullscreen/intro của **web4 trong tài liệu này được ưu tiên**.
