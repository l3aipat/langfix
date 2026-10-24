# LangFix

[English](README.md) · **ไทย**

แก้ข้อความที่พิมพ์ผิดแป้น ไทย/อังกฤษ ให้อัตโนมัติบน Mac

ลืมสลับแป้นแล้วพิมพ์ `l;ylfu` ไป LangFix จะแก้เป็น `สวัสดี` และสลับแป้นให้ทันที ไม่ต้องลบแล้วพิมพ์ใหม่

**[⬇︎ ดาวน์โหลด LangFix](https://github.com/l3aipat/langfix/releases/latest/download/LangFix.dmg)** · ฟรี · macOS 13 ขึ้นไป

## ทำอะไรได้บ้าง

- แก้ให้เองตั้งแต่ตัวอักษรที่ 3 ส่วนคำสั้นอย่าง "นะ" จะแก้ตอนกดเว้นวรรค
- ถ้าแก้ผิด ให้กด Delete ทันที ข้อความเดิมจะกลับมา และ LangFix จะจำคำนั้นไว้ไม่แก้อีก
- ถ้าจะแปลงข้อความที่พิมพ์ไว้แล้ว ให้เลือกข้อความแล้วกด Option+Shift+Space
- จำแป้นที่ใช้ล่าสุดของแต่ละแอป สลับแอปแล้วจะเปลี่ยนแป้นให้
- ตอนแป้นเปลี่ยน จะมีป้าย ก หรือ A ขึ้นข้างเคอร์เซอร์แป๊บหนึ่ง
- ปิดเฉพาะบางแอปได้ และเพิ่มคำที่ไม่อยากให้แก้ได้ เช่น 555

## ติดตั้ง

เครื่องต้องมีแป้นทั้งภาษาไทย (Thai) และอังกฤษ (ABC หรือ U.S.) ตั้งได้ที่ System Settings > Keyboard > Input Sources

1. [ดาวน์โหลด LangFix.dmg](https://github.com/l3aipat/langfix/releases/latest/download/LangFix.dmg) แล้วเปิดไฟล์
2. ลาก LangFix ไปวางในโฟลเดอร์ Applications
3. เปิด LangFix จาก Applications
4. ถ้าขึ้นว่า "LangFix" Not Opened ให้กด Done
   แล้วไปที่ System Settings > Privacy & Security เลื่อนลงล่างสุด กด **Open Anyway** แล้วใส่รหัสผ่านเครื่อง
   จากนั้นเปิด LangFix อีกครั้ง และกด Open Anyway
5. ให้สิทธิ์ Accessibility โดยคลิกไอคอน ก/a ที่แถบเมนูด้านบนขวา
   เลือก "Turn on LangFix in Accessibility settings…" แล้วเปิดสวิตช์ของ LangFix
6. รอให้ไอคอนเปลี่ยนจาก ก/a ⚠︎ เป็น ก/a แปลว่าพร้อมใช้งาน

### ทำไม Mac ถึงเตือนตอนเปิด

LangFix เป็นโปรเจกต์ฟรีที่ไม่ได้จ่ายค่า Apple Developer ID ($99 ต่อปี) macOS จึงไม่รู้จักผู้พัฒนาและขึ้นคำเตือน ซึ่งไม่ได้แปลว่าแอปเป็นอันตราย โค้ดทั้งหมดเปิดให้ดูได้ใน repo นี้

### ทำไมต้องให้สิทธิ์ Accessibility

LangFix ต้องเห็นแป้นที่กดถึงจะรู้ว่าพิมพ์ผิดแป้น และต้องลบแล้วพิมพ์คำที่ถูกแทนให้ได้ macOS อนุญาตให้ทำแบบนี้ผ่านสิทธิ์ Accessibility เท่านั้น

LangFix ไม่เก็บและไม่ส่งสิ่งที่พิมพ์ไปที่ไหน การแก้คำทั้งหมดทำงานในเครื่อง อินเทอร์เน็ตใช้แค่ตรวจหาเวอร์ชันใหม่จาก GitHub และจะตรวจอัตโนมัติก็ต่อเมื่อคุณกดอนุญาตตอนที่แอปถาม

## อัปเดตเป็นเวอร์ชันใหม่

เลือก "ตรวจหาเวอร์ชันใหม่…" จากเมนู ก/a แล้วกดติดตั้ง ไม่ต้องให้สิทธิ์ Accessibility ใหม่

ถ้าใช้เวอร์ชัน 0.1.8 หรือเก่ากว่า ต้องอัปเดตด้วยมือครั้งเดียว ดาวน์โหลดตัวใหม่จาก[ลิงก์เดิม](https://github.com/l3aipat/langfix/releases/latest/download/LangFix.dmg) แล้วลากไปทับใน Applications จากนั้นเลือก LangFix ในรายการ Accessibility กดปุ่ม − แล้วกด + เพิ่ม LangFix กลับเข้าไป

ดูว่าแต่ละเวอร์ชันเปลี่ยนอะไรได้ที่หน้า [Releases](https://github.com/l3aipat/langfix/releases)

## เจอปัญหา หรืออยากให้มีอะไรเพิ่ม

LangFix ฟรีและจะฟรีต่อไป สิ่งที่อยากได้คือ feedback ว่าใช้แล้วเป็นยังไง

แจ้งได้ที่ [Issues](https://github.com/l3aipat/langfix/issues) ถ้าเจอปัญหา ช่วยบอกเวอร์ชัน macOS, แอปที่พิมพ์อยู่ และคำที่พิมพ์แล้วถูกแก้ผิดหรือไม่ถูกแก้

## License

LangFix เป็นซอฟต์แวร์เสรีภายใต้ [GPL-3.0](LICENSE) ใช้ แก้ และแจกต่อได้ ถ้าแจกเวอร์ชันที่แก้แล้วต้องเปิดโค้ดด้วย GPL-3.0 เหมือนกัน
แอปมี [Sparkle](https://sparkle-project.org) (MIT) อยู่ข้างใน ข้อความ license อยู่ที่ `LangFix.app/Contents/Resources/Sparkle-LICENSE.txt`

## สำหรับนักพัฒนา

```sh
swift build                 # build
./scripts/test.sh           # unit tests
./scripts/make-dmg.sh       # สร้าง build/LangFix-<version>.dmg
./scripts/release.sh        # เตรียม LangFix.dmg และ appcast.xml สำหรับ GitHub Release
```
