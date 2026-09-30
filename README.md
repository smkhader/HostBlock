HostBlock is a lightweight Windows hosts‑file blocker that extracts domains from pasted HTML or from a live webpage URL and immediately blocks them system‑wide. It is designed for kiosk environments, privacy setups, and network lockdown scenarios where fast domain blocking is essential.

HostBlock can write block entries to the default Windows hosts file:

Code
C:\Windows\System32\drivers\etc\hosts
or to a custom file using the -AltHostFile parameter.

Features
Extract domains from pasted HTML  
Paste any webpage source, script, ad markup, or embedded HTML and HostBlock automatically identifies all hostnames and subdomains.

Extract domains directly from a URL  
Use -Url to fetch a webpage, parse its HTML, and block all domains referenced within it.

Hosts‑file blocking  
Writes entries in the standard format:

Code
0.0.0.0 domain.com
0.0.0.0 sub.domain.com
Alternate output file support  
Use -AltHostFile to write extracted domains to a custom file instead of modifying the system hosts file.

Noise filtering & normalization  
Removes duplicates, strips protocols, paths, query strings, and malformed entries.

System‑wide blocking  
All browsers and applications inherit the block rules automatically.

Usage
1. Block domains from pasted HTML
powershell
.\HostBlock.ps1
Paste HTML when prompted. HostBlock extracts domains and writes them to the hosts file.

2. Block domains from a URL
powershell
.\HostBlock.ps1 -Url https://www.domain.net

3. Write extracted domains to a custom file (This does not require Administrator access)
powershell
.\HostBlock.ps1 -AltHostFile .\ads.txt
This writes all extracted domains to ads.txt instead of modifying the system hosts file.

4. Combine URL + alternate output file
powershell
.\HostBlock.ps1 -Url https://www.craigslist.org -AltHostFile .\craigslist-block.txt
This fetches Craigslist, extracts domains, and writes them to craigslist-block.txt.

Use Cases
- Block ads and trackers
- Remove telemetry endpoints
- Restrict kiosk systems
- Prevent external CDN/script calls
- Harden systems for privacy or security
- Build custom blocklists from real webpages

PowerShell 5+ or PowerShell Core
