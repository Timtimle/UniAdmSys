// BẢNG ĐIỂM CHUẨN GIẢ LẬP (Lấy từ Dashboard / Cấu hình hệ thống)
const BENCHMARK_SCORES = {
    "KHMT": 25.5,   // Khoa học máy tính
    "KTPM": 25.0,   // Kỹ thuật phần mềm
    "CNTT": 24.5,   // Công nghệ thông tin
    "MMT": 23.5,    // Mạng máy tính
    "QTKD": 24.0,   // Quản trị kinh doanh
    "MKT": 24.5     // Marketing
};

// Hàm chuyển đổi Tên ngành sang Mã ngành chuẩn
function getMajorCodeByName(name) {
    if (!name) return "CNTT";
    if (name.includes("máy tính") || name.includes("Khoa học")) return "KHMT";
    if (name.includes("phần mềm")) return "KTPM";
    if (name.includes("thông tin")) return "CNTT";
    if (name.includes("kinh doanh")) return "QTKD";
    if (name.includes("Marketing")) return "MKT";
    return "CNTT";
}

// Lấy danh sách hồ sơ thực tế và TỰ ĐỘNG HỢP NHẤT hồ sơ thí sinh vừa đăng ký
function getStoredProfiles() {
    let adminProfiles = [];
    const stored = localStorage.getItem("adminProfiles");

    if (stored) {
        try { adminProfiles = JSON.parse(stored); } catch (e) { }
    }

    // Kiểm tra hồ sơ từ phía thí sinh nộp
    const studentAppStr = localStorage.getItem("userApplication");
    if (studentAppStr) {
        try {
            const app = JSON.parse(studentAppStr);
            if (app && app.fullName) {
                const majorCode = app.majorCode || getMajorCodeByName(app.major);
                const existingIndex = adminProfiles.findIndex(p => p.name === app.fullName || (app.cccd && p.cccd === app.cccd));

                const defaultAvatar = "https://via.placeholder.com/150x200?text=Anh+3x4";
                const defaultDoc = "https://via.placeholder.com/600x800?text=Anh+Hoc+Ba+THPT";

                const profileData = {
                    id: existingIndex !== -1 ? adminProfiles[existingIndex].id : "HS00" + (adminProfiles.length + 1),
                    name: app.fullName,
                    cccd: app.cccd || "034202008888",
                    major: majorCode,
                    group: "A00",
                    score: app.score || 24.5,
                    status: app.status || "Chờ duyệt",
                    avatar: app.avatar && app.avatar.length > 50 ? app.avatar : defaultAvatar,
                    doc: app.doc && app.doc.length > 50 ? app.doc : defaultDoc,
                    reason: app.reason || ""
                };

                if (existingIndex !== -1) {
                    adminProfiles[existingIndex] = profileData;
                } else {
                    adminProfiles.push(profileData);
                }
            }
        } catch (e) { }
    }

    // Nếu chưa có hồ sơ nào thì khởi tạo mẫu mặc định
    if (adminProfiles.length === 0) {
        adminProfiles = [
            { id: "HS001", name: "Nguyễn Văn A", cccd: "034202001234", major: "KHMT", group: "A00", score: 26.5, status: "Chờ duyệt", avatar: "https://via.placeholder.com/150x200?text=Anh+3x4+A", doc: "https://via.placeholder.com/600x800?text=Hoc+Ba+A", reason: "" },
            { id: "HS002", name: "Trần Thị B", cccd: "034202005678", major: "QTKD", group: "D01", score: 23.5, status: "Đã duyệt", avatar: "https://via.placeholder.com/150x200?text=Anh+3x4+B", doc: "https://via.placeholder.com/600x800?text=Hoc+Ba+B", reason: "" }
        ];
    }

    localStorage.setItem("adminProfiles", JSON.stringify(adminProfiles));
    return adminProfiles;
}

function saveProfiles(profiles) {
    localStorage.setItem("adminProfiles", JSON.stringify(profiles));
}

let mockProfiles = [];
let selectedProfileId = null;

document.addEventListener("DOMContentLoaded", () => {
    refreshData();
    window.addEventListener("storage", (e) => {
        if (e.key === "adminProfiles" || e.key === "userApplication") refreshData();
    });
    window.addEventListener("focus", () => refreshData());
});

function refreshData() {
    mockProfiles = getStoredProfiles();
    renderProfiles(mockProfiles);
    updateTotalCounter(mockProfiles.length);
}

function updateTotalCounter(count) {
    const counterEl = document.getElementById("totalProfilesCount");
    if (counterEl) counterEl.innerText = count;
}

function renderProfiles(data) {
    const tbody = document.getElementById("profileTableBody");
    if (!tbody) return;
    tbody.innerHTML = "";

    if (!data || data.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #888; padding: 25px;">Chưa có hồ sơ thí sinh đăng ký nào trong hệ thống.</td></tr>`;
        return;
    }

    data.forEach(item => {
        let badgeClass = item.status === "Chờ duyệt" ? "badge-pending" :
            (item.status === "Đã duyệt" ? "badge-approved" : "badge-rejected");

        const tr = document.createElement("tr");
        tr.innerHTML = `
            <td><strong>${item.id}</strong></td>
            <td>${item.name}</td>
            <td><span class="major-clickable" onclick="quickFilterByMajor('${item.major}')" style="color: var(--primary-color); font-weight: bold; cursor: pointer; text-decoration: underline;">${item.major} 🔍</span></td>
            <td>${item.group || 'A00'}</td>
            <td><strong>${item.score}</strong></td>
            <td><span class="badge ${badgeClass}">${item.status}</span></td>
            <td><button class="btn-primary btn-sm" onclick="openDetail('${item.id}')">Xem & Duyệt</button></td>
        `;
        tbody.appendChild(tr);
    });
}

// BỘ LỌC DỮ LIỆU
function applyFilter() { /* Giữ nguyên hàm lọc như cũ */
    const search = document.getElementById("searchInput").value.toLowerCase().trim();
    const major = document.getElementById("filterMajor").value;
    const status = document.getElementById("filterStatus").value;
    const minScore = parseFloat(document.getElementById("filterMinScore").value) || 0;

    const filtered = mockProfiles.filter(p => {
        const matchSearch = p.name.toLowerCase().includes(search) || p.id.toLowerCase().includes(search) || p.cccd.includes(search);
        const matchMajor = major === "" || p.major.toUpperCase() === major.toUpperCase();
        const matchStatus = status === "" || p.status === status;
        const matchScore = p.score >= minScore;
        return matchSearch && matchMajor && matchStatus && matchScore;
    });

    renderProfiles(filtered);
    updateTotalCounter(filtered.length);
}
function quickFilterByMajor(majorCode) {
    const selectMajor = document.getElementById("filterMajor");
    if (selectMajor) { selectMajor.value = majorCode; applyFilter(); }
}
function resetFilter() {
    document.getElementById("searchInput").value = "";
    document.getElementById("filterMajor").value = "";
    document.getElementById("filterStatus").value = "";
    document.getElementById("filterMinScore").value = "";
    refreshData();
}

// TRÌNH XEM ẢNH LIGHTBOX
function showLightboxModal(imgSrc, title) {
    let lightbox = document.getElementById("imgLightboxModal");
    if (!lightbox) {
        lightbox = document.createElement("div");
        lightbox.id = "imgLightboxModal";
        lightbox.style.cssText = "display:none; position:fixed; z-index:3000; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.85); justify-content:center; align-items:center; flex-direction:column;";
        lightbox.innerHTML = `
            <div style="position:relative; max-width:90%; max-height:90%; text-align:center;">
                <button onclick="closeLightbox()" style="position:absolute; top:-40px; right:0; background: #d63031; color:white; border:none; padding: 6px 15px; font-weight:bold; border-radius:4px; cursor:pointer;">✕ Đóng cửa sổ</button>
                <h4 id="lightboxTitle" style="color:white; margin-bottom:12px; font-size:16px;"></h4>
                <img id="lightboxImg" src="" style="max-width:100%; max-height:80vh; border-radius:6px; box-shadow:0 0 25px rgba(255,255,255,0.3); border: 2px solid #fff;" />
            </div>
        `;
        document.body.appendChild(lightbox);
        lightbox.onclick = (e) => { if (e.target.id === "imgLightboxModal") closeLightbox(); };
    }
    document.getElementById("lightboxTitle").innerText = title || "Xem tệp minh chứng";
    document.getElementById("lightboxImg").src = imgSrc;
    lightbox.style.display = "flex";
}
function closeLightbox() {
    const lightbox = document.getElementById("imgLightboxModal");
    if (lightbox) lightbox.style.display = "none";
}

// ==========================================
// TÍNH NĂNG ĐỐI CHIẾU ĐIỂM CHUẨN
// ==========================================
function compareWithStandardScore(major, userScore) {
    const benchmark = BENCHMARK_SCORES[major] || 24.0; // Lấy điểm chuẩn ngành, mặc định 24.0 nếu không có
    const resultBox = document.getElementById("compareResultBox");

    resultBox.style.display = "block"; // Hiển thị kết quả

    if (userScore >= benchmark) {
        resultBox.innerHTML = `
            <div style="background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 10px; border-radius: 4px;">
                <h5 style="color: #155724; margin: 0 0 5px 0;">✅ ĐỦ ĐIỂM TRÚNG TUYỂN</h5>
                <p style="margin: 0; font-size: 13px; color: #155724;">Điểm chuẩn ngành <strong>${major}</strong> là <strong>${benchmark}</strong>. Điểm của thí sinh (${userScore}) đã đạt yêu cầu. Cán bộ có thể tiến hành Duyệt ngay!</p>
            </div>
        `;
    } else {
        const gap = (benchmark - userScore).toFixed(2);
        resultBox.innerHTML = `
            <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin-top: 10px; border-radius: 4px;">
                <h5 style="color: #856404; margin: 0 0 5px 0;">⚠️ CHƯA ĐỦ ĐIỂM CHUẨN (Thiếu ${gap} điểm)</h5>
                <p style="margin: 0; font-size: 13px; color: #856404;">
                    Điểm chuẩn ngành <strong>${major}</strong> là <strong>${benchmark}</strong>. 
                    <br><i>*Lưu ý: Hệ thống phía thí sinh hiện chưa tích hợp khai báo điểm ưu tiên. Cán bộ vui lòng kiểm tra trực tiếp ảnh học bạ/minh chứng bên dưới để xem thí sinh có thuộc diện ưu tiên (Khu vực, Hộ nghèo, Bằng cấp...) và <strong>cộng tay điểm ưu tiên</strong> trước khi quyết định duyệt/từ chối.</i>
                </p>
            </div>
        `;
    }
}

// MODAL CHI TIẾT
function openDetail(id) {
    selectedProfileId = id;
    const profile = mockProfiles.find(p => p.id === id);
    if (!profile) return;

    const modalBody = document.getElementById("modalDetailBody");
    document.getElementById("rejectReason").value = profile.reason || "";

    const avatarUrl = profile.avatar || "https://via.placeholder.com/150x200?text=Anh+3x4";
    const docUrl = profile.doc || "https://via.placeholder.com/600x800?text=Anh+Hoc+Ba+THPT";

    modalBody.innerHTML = `
        <p><strong>Mã hồ sơ:</strong> ${profile.id}</p>
        <p><strong>Họ tên:</strong> ${profile.name}</p>
        <p><strong>Số CCCD:</strong> ${profile.cccd}</p>
        <p><strong>Ngành xét tuyển:</strong> ${profile.major} | <strong>Tổ hợp:</strong> ${profile.group || 'A00'}</p>
        
        <div style="background: #f8f9fa; padding: 15px; border-radius: 6px; border: 1px solid #e9ecef; margin: 10px 0;">
            <p style="margin: 0 0 10px 0; font-size: 15px;"><strong>Tổng điểm xét tuyển tự kê khai:</strong> <span style="color:#d63031; font-size: 18px; font-weight:bold;">${profile.score}</span></p>
            <button onclick="compareWithStandardScore('${profile.major}', ${profile.score})" style="background: #17a2b8; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-weight: bold; font-size: 13px;">
                🔍 Đối chiếu với Điểm chuẩn hệ thống
            </button>
            <div id="compareResultBox" style="display: none;"></div>
        </div>

        <p><strong>Trạng thái hiện tại:</strong> <span class="badge ${profile.status === 'Chờ duyệt' ? 'badge-pending' : (profile.status === 'Đã duyệt' ? 'badge-approved' : 'badge-rejected')}">${profile.status}</span></p>
        <br>
        <h4>Giấy tờ minh chứng đính kèm (Nhấp để mở xem ảnh):</h4>
        <ul style="margin-top: 8px; margin-bottom: 15px; padding-left: 20px;">
            <li style="margin-bottom: 6px;"><a href="javascript:void(0)" onclick="showLightboxModal('${docUrl}', 'Học bạ THPT - ${profile.name}')" style="color:var(--primary-color); font-weight:bold; text-decoration:underline;">📁 Học bạ THPT.pdf</a></li>
            <li style="margin-bottom: 6px;"><a href="javascript:void(0)" onclick="showLightboxModal('${avatarUrl}', 'Ảnh 3x4 - ${profile.name}')" style="color:var(--primary-color); font-weight:bold; text-decoration:underline;">🖼️ Ảnh 3x4.png</a></li>
        </ul>

        <div style="display: flex; gap: 15px; margin-top: 10px; flex-wrap: wrap; background: #f8f9fa; padding: 12px; border-radius: 6px; border: 1px solid #e9ecef;">
            <div style="text-align: center;">
                <small style="display:block; font-weight:bold; margin-bottom:5px; color:#555;">Ảnh chân dung (3x4)</small>
                <img src="${avatarUrl}" alt="Ảnh 3x4" style="width: 100px; height: 130px; object-fit: cover; border-radius: 4px; border: 1px solid #ccc; cursor: pointer;" onclick="showLightboxModal('${avatarUrl}', 'Ảnh 3x4 - ${profile.name}')">
            </div>
            <div style="flex: 1; text-align: center; min-width: 180px;">
                <small style="display:block; font-weight:bold; margin-bottom:5px; color:#555;">Học bạ / Minh chứng</small>
                <img src="${docUrl}" alt="Học bạ" style="max-width: 100%; max-height: 130px; object-fit: contain; border-radius: 4px; border: 1px solid #ccc; cursor: pointer;" onclick="showLightboxModal('${docUrl}', 'Học bạ THPT - ${profile.name}')">
            </div>
        </div>
    `;

    document.getElementById("detailModal").style.display = "block";
    document.getElementById("btnApprove").onclick = () => updateStatus("Đã duyệt");
    document.getElementById("btnReject").onclick = () => updateStatus("Từ chối");
}

function updateStatus(newStatus) {
    const reason = document.getElementById("rejectReason").value;
    if (newStatus === "Từ chối" && !reason.trim()) {
        alert("Vui lòng nhập lý do từ chối hồ sơ!");
        return;
    }

    const profileIndex = mockProfiles.findIndex(p => p.id === selectedProfileId);
    if (profileIndex !== -1) {
        mockProfiles[profileIndex].status = newStatus;
        mockProfiles[profileIndex].reason = reason;
        saveProfiles(mockProfiles);

        const studentAppStr = localStorage.getItem("userApplication");
        if (studentAppStr) {
            try {
                let studentApp = JSON.parse(studentAppStr);
                if (studentApp.cccd === mockProfiles[profileIndex].cccd || studentApp.fullName === mockProfiles[profileIndex].name) {
                    studentApp.status = newStatus;
                    studentApp.reason = reason;
                    localStorage.setItem("userApplication", JSON.stringify(studentApp));
                }
            } catch (e) { }
        }
        alert(`Đã cập nhật hồ sơ ${selectedProfileId} thành [${newStatus}]`);
        closeModal();
        applyFilter();
    }
}

function closeModal() {
    document.getElementById("detailModal").style.display = "none";
}