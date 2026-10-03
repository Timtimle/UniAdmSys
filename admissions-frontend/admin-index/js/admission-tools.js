const BACKEND_API_URL = "http://127.0.0.1:8000";
const byId = (id) => document.getElementById(id);

function esc(value) {
    return String(value ?? "").replace(/[&<>"']/g, (s) => ({
        "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;"
    }[s]));
}

function setTab(id) {
    document.querySelectorAll(".tool-tab").forEach(x => x.classList.toggle("active", x.dataset.tab === id));
    document.querySelectorAll(".tool-pane").forEach(x => x.classList.toggle("active", x.id === id));
}
document.querySelectorAll(".tool-tab").forEach(btn => btn.addEventListener("click", () => setTab(btn.dataset.tab)));

function sourceBadge(row) {
    return row.is_demo
        ? '<span class="tool-badge demo">DEMO</span>'
        : '<span class="tool-badge verified">VERIFIED</span>';
}

async function searchCatalog() {
    const err = byId("lookupError");
    err.style.display = "none";
    byId("lookupResults").innerHTML = '<div class="tool-note">Đang tải...</div>';

    const params = new URLSearchParams({
        query: byId("lookupQuery").value,
        score_type: byId("lookupScoreType").value,
        include_demo: byId("lookupDemo").checked,
        limit: "40"
    });
    if (byId("lookupSchool").value.trim()) params.set("school_code", byId("lookupSchool").value.trim());

    try {
        const res = await fetch(`${BACKEND_API_URL}/api/catalog/search?${params}`);
        const data = await res.json();
        if (!res.ok) throw new Error(data.detail || JSON.stringify(data));

        byId("lookupCount").textContent = `(${data.count || 0} ngành)`;
        if (!data.items?.length) {
            byId("lookupResults").innerHTML = '<div class="tool-note">Không tìm thấy dữ liệu.</div>';
            return;
        }

        byId("lookupResults").innerHTML = data.items.map(m => {
            const cuts = (m.cutoffs || []).slice(0, 8).map(c => `
                <span class="data-chip">${sourceBadge(c)} <b>${esc(c.phuong_thuc || c.loai_diem || "Điểm chuẩn")}</b>
                · ${esc(c.diem)}${c.thang_diem ? "/" + esc(c.thang_diem) : ""}
                ${c.ma_ky_thi ? " · " + esc(c.ma_ky_thi) : ""}${c.to_hop ? " · " + esc(c.to_hop) : ""}</span>
            `).join("");

            const floors = (m.floor_scores || []).slice(0, 6).map(f => `
                <span class="data-chip floor">${sourceBadge(f)} <b>Điểm sàn ${esc(f.diem_san)}</b>${f.ma_to_hop ? " · " + esc(f.ma_to_hop) : ""}</span>
            `).join("");

            const payload = encodeURIComponent(JSON.stringify({
                ma_nganh: m.ma_nganh, ten_nganh: m.ten_nganh,
                ten_truong: m.ten_truong, ma_truong: m.ma_truong
            }));

            return `
                <div class="lookup-item">
                    <div class="lookup-head">
                        <div>
                            <div class="lookup-title">${esc(m.ten_nganh)}</div>
                            <div class="lookup-meta">${esc(m.ten_truong)} · ${esc(m.ma_truong)} · Mã ngành ${esc(m.ma_nganh_tuyen_sinh)}</div>
                        </div>
                        <button class="btn-primary" onclick="chooseMajor('${payload}')">Xét chỉ tiêu</button>
                    </div>
                    <div class="chip-row">${cuts || '<span class="tool-note">Chưa có điểm chuẩn.</span>'}</div>
                    <div class="chip-row">${floors || '<span class="tool-note">Chưa có điểm sàn theo ngành/tổ hợp.</span>'}</div>
                </div>`;
        }).join("");
    } catch (e) {
        byId("lookupResults").innerHTML = "";
        err.textContent = `Không gọi được Backend API: ${e.message}`;
        err.style.display = "block";
    }
}

async function chooseMajor(encoded) {
    const m = JSON.parse(decodeURIComponent(encoded));
    byId("quotaMajorId").value = m.ma_nganh;
    byId("quotaMajorLabel").value = `${m.ten_truong} · ${m.ten_nganh}`;
    setTab("quotaPane");

    byId("quotaMethod").innerHTML = '<option value="">Đang tải...</option>';
    try {
        const res = await fetch(`${BACKEND_API_URL}/api/catalog/majors/${encodeURIComponent(m.ma_nganh)}/methods`);
        const data = await res.json();
        byId("quotaMethod").innerHTML = '<option value="">Chọn phương thức...</option>' +
            (data.items || []).map(x => `<option value="${esc(x.ma_phuong_thuc)}">${esc(x.ten_phuong_thuc)}${x.loai_phuong_thuc ? " · " + esc(x.loai_phuong_thuc) : ""}</option>`).join("");
    } catch (e) {
        byId("quotaMethod").innerHTML = '<option value="">Lỗi tải phương thức</option>';
    }
}

async function runQuota() {
    const err = byId("quotaError");
    const ok = byId("quotaSuccess");
    err.style.display = "none";
    ok.style.display = "none";
    byId("quotaStats").style.display = "none";
    byId("quotaWarnings").innerHTML = "";
    byId("quotaTable").innerHTML = '<div class="tool-note">Đang chạy thuật toán...</div>';

    const majorId = byId("quotaMajorId").value;
    const methodCode = byId("quotaMethod").value;
    if (!majorId || !methodCode) {
        err.textContent = "Hãy chọn ngành và phương thức xét tuyển.";
        err.style.display = "block";
        byId("quotaTable").innerHTML = "";
        return;
    }

    const override = byId("quotaOverride").value.trim();
    const payload = {
        major_id: majorId,
        method_code: methodCode,
        year: Number(byId("quotaYear").value || 2025),
        quota_override: override ? Number(override) : null,
        commit: byId("quotaCommit").checked
    };

    try {
        const res = await fetch(`${BACKEND_API_URL}/api/admissions/quota-rank`, {
            method: "POST",
            headers: {"Content-Type": "application/json", "X-Admin-Token": byId("adminToken").value},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.detail || JSON.stringify(data));

        const stats = [
            ["Chỉ tiêu", data.quota], ["Thí sinh", data.total_candidates],
            ["Đạt chỉ tiêu", data.within_quota], ["Ngoài chỉ tiêu", data.outside_quota],
            ["Điểm cắt", data.cutoff_score ?? "—"]
        ];
        byId("quotaStats").style.display = "grid";
        byId("quotaStats").innerHTML = stats.map(([k,v]) => `<div class="quota-stat"><div>${k}</div><strong>${esc(v)}</strong></div>`).join("");

        if (data.warnings?.length) {
            byId("quotaWarnings").innerHTML = data.warnings.map(w => `<div class="tool-warning">⚠ ${esc(w)}</div>`).join("");
        }
        if (data.committed) {
            ok.textContent = "Đã lưu metadata xếp hạng chỉ tiêu vào ket_qua_xet_tuyen.";
            ok.style.display = "block";
        }

        const rows = data.ranking || [];
        byId("quotaTable").innerHTML = `
            <div class="table-scroll"><table class="data-table"><thead><tr>
            <th>Hạng</th><th>Thí sinh</th><th>NV</th><th>Tổ hợp</th><th>Điểm</th><th>Nguồn điểm</th><th>Kết quả chỉ tiêu</th>
            </tr></thead><tbody>${rows.map(r => `<tr>
            <td>${esc(r.xep_hang ?? "—")}</td><td><strong>${esc(r.ho_ten || r.ma_thi_sinh)}</strong><br><small>${esc(r.email || "")}</small></td>
            <td>${esc(r.thu_tu_nguyen_vong)}</td><td>${esc(r.ma_to_hop || "—")}</td><td><strong>${esc(r.diem_xet_tuyen ?? "—")}</strong></td>
            <td>${esc(r.nguon_diem || "—")}</td><td>${r.trang_thai_chi_tieu === "dat_chi_tieu" ? '<span class="tool-badge verified">ĐẠT CHỈ TIÊU</span>' : r.trang_thai_chi_tieu === "ngoai_chi_tieu" ? '<span class="tool-badge fail">NGOÀI CHỈ TIÊU</span>' : '<span class="tool-badge demo">THIẾU ĐIỂM</span>'}</td>
            </tr>`).join("")}</tbody></table></div>`;
    } catch (e) {
        byId("quotaTable").innerHTML = "";
        err.textContent = e.message;
        err.style.display = "block";
    }
}

byId("lookupBtn").addEventListener("click", searchCatalog);
byId("quotaBtn").addEventListener("click", runQuota);
searchCatalog();