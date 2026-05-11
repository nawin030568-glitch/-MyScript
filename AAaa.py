import time as t, sys as s

# Configuration
M = "\033[38;2;255;165;0m-- รักรักรักรักรักรักรัก (Talk Less) --\033[0m"
L = [
    ("รัก รัก รัก รัก รัก รัก รัก ใช่ไหม... คำพูดที่รอคอย", 4.5),
    ("โอ้ที่รักเธอใจเย็นๆ ไม่ชอบเลยนะไอ้คำประณาม", 3.5),
    ("ถ้าให้พิสูจน์ทุกยาม ก็ทำคำว่ารักจนชำนาญ", 4.0),
    ("เพราะมองคำว่ารักเปรียบดั่ง Abstract", 3.0),
    ("แล้วเธอล่ะมองคำว่ารักเป็นกิริยาหรือคำนาม?", 3.5),
    ("คนบางคนใช้คำบางคำพูดไปงั้นๆ อย่างเลื่อนลอย", 4.5),
    ("ฉันพูดน้อยเพียงเพราะฉันต้องการให้คำมันดูมีความหมาย", 5.0),
    ("พูดให้แล้ว อย่าเพิ่งน้อยใจ น้อยใจไปเลยนะที่รัก", 4.0),
    ("นวดไหล่คืองานถนัด เมื่อไหร่ทำงานมาหนัก", 3.5),
    ("มานี่มานอนบนตัก แล้วผมจะกล่อมให้หลับใหล...", 4.5)
]

def execute_lyrics(data):
    for line, duration in data:
        # Calculate delay per character
        step = duration / len(line)
        for char in line:
            s.stdout.write(char)
            s.stdout.flush()
            t.sleep(step)
        s.stdout.write('\n')

if __name__ == "__main__":
    # Start Program
    print(f"{'='*40}\n[ SYSTEM: RUNNING LYRICS_SCRIPT ]\n{'='*40}\n")
    execute_lyrics(L)
    print(f"\n{M}\n\n< SUCCESSFUL_DEPLOYMENT />")
