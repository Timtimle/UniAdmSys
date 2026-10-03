#!/usr/bin/env python3
import csv, json, time, urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

OWNER="kbaoooo"
REPO="vn_schools_scores_data"
BRANCH="main"
RAW=f"https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}"
OUT=Path("data/diem_chuan_2025_supabase.csv")

def get_json(url,retries=3):
    last=None
    for i in range(retries):
        try:
            req=urllib.request.Request(url,headers={"User-Agent":"UniAdmSys-data-builder/1.0"})
            with urllib.request.urlopen(req,timeout=20) as r:
                return json.load(r)
        except Exception as e:
            last=e
            time.sleep(0.4*(i+1))
    raise last

meta=get_json(f"{RAW}/craw-data/schools_with_ids.json").get("data",[])

def is_university(m):
    name=(m.get("school_name") or "").lower()
    code=(m.get("school_code") or "").upper()
    if "cao đẳng" in name or code.endswith("_CD"):
        return False
    return (
        "đại học" in name or "học viện" in name or "nhạc viện" in name
        or name.startswith("khoa ") or name.startswith("phân hiệu ")
        or name.startswith("viện nghiên cứu")
    )

schools=[m for m in meta if is_university(m) and (m.get("school_code") or "").strip()]

def fetch_school(m):
    code=m["school_code"].strip()
    url=f"{RAW}/craw-data/scores/{code}/2025.json"
    try:
        obj=get_json(url,retries=2)
        return code,obj.get("data") or [],None
    except Exception as e:
        return code,[],str(e)

rows=[]
seen=set()
schools_ok=0
schools_missing=0

with ThreadPoolExecutor(max_workers=24) as ex:
    futs=[ex.submit(fetch_school,m) for m in schools]
    for fut in as_completed(futs):
        code,data,err=fut.result()
        if err or not data:
            schools_missing+=1
            continue
        schools_ok+=1
        source_url=f"https://github.com/{OWNER}/{REPO}/blob/{BRANCH}/craw-data/scores/{code}/2025.json"
        for r in data:
            mark=r.get("mark")
            if mark is None or str(mark).strip()=="":
                continue
            major_code=str(r.get("code") or r.get("display_code") or "").strip()
            major_name=" ".join(str(r.get("name") or "").split())
            if not major_code and not major_name:
                continue
            block=" ".join(str(r.get("block") or "").split())
            method=" ".join(str(r.get("admission_name") or "").split())
            note=" ".join(str(r.get("introtext") or "").split())
            key=(code,major_code,major_name,block,str(mark),method,note)
            if key in seen:
                continue
            seen.add(key)
            rows.append([code,major_code,major_name,block,mark,method,note,2025,source_url])

rows.sort(key=lambda r:(r[0],r[1],r[5],r[3],str(r[4])))
OUT.parent.mkdir(parents=True,exist_ok=True)
with OUT.open("w",encoding="utf-8-sig",newline="") as f:
    w=csv.writer(f)
    w.writerow(["ma_tuyen_sinh","ma_nganh_tuyen_sinh","ten_nganh","to_hop_xet_tuyen","diem_chuan","phuong_thuc","ghi_chu","nam","source_url"])
    w.writerows(rows)

print(f"schools_ok={schools_ok}")
print(f"schools_missing_or_empty={schools_missing}")
print(f"rows={len(rows)}")
print(OUT)
