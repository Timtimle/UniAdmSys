// Dữ liệu mặc định các ngành học
const defaultMajors = [
    { code: "CNTT", name: "Công nghệ thông tin", quota: 50, benchmark: 22.0 },
    { code: "KTPM", name: "Kỹ thuật phần mềm", quota: 40, benchmark: 21.5 },
    { code: "QTKD", name: "Quản trị kinh doanh", quota: 30, benchmark: 19.0 },
    { code: "MKT", name: "Marketing", quota: 30, benchmark: 20.0 },
    { code: "KHMT", name: "Khoa học máy tính", quota: 30, benchmark: 23.0 }
];

let majorList = [];
let majorChartInstance = null;
let statusChartInstance = null;

document.addEventListener("DOMContentLoaded", () => {
    loadDashboardData();
});

// Lấy danh sách hồ sơ thực tế từ mục Xét tuyển
function getRealProfiles() {
    const stored = localStorage.getItem("adminProfiles");
    if (stored) {
        try {
            return JSON.parse(stored);
        } catch (e) { }
    }
    return [
        { id: "HS001", name: "Nguyễn Văn A", major: "CNTT", score: 26.5, status: "Chờ duyệt" },
        { id: "HS002", name: "Trần Thị B", major: "QTKD", score: 22.0, status: "Đã duyệt" },
        { id: "HS003", name: "Lê Văn C", major: "KTPM", score: 19.5, status: "Từ chối" },
        { id: "HS004", name: "Phạm Minh D", major: "CNTT", score: 24.0, status: "Chờ duyệt" },
        { id: "HS005", name: "Hoàng Kim E", major: "MKT", score: 21.5, status: "Đã duyệt" },
        { id: "HS006", name: "Vũ Đức F", major: "KHMT", score: 25.5, status: "Chờ duyệt" }
    ];
}

// Lấy danh sách danh mục ngành học từ LocalStorage
function getStoredMajors() {
    const stored = localStorage.getItem("adminMajors");
    if (stored) {
        try {
            return JSON.parse(stored);
        } catch (e) { }
    }
    localStorage.setItem("adminMajors", JSON.stringify(defaultMajors));
    return defaultMajors;
}

function saveMajors(list) {
    localStorage.setItem("adminMajors", JSON.stringify(list));
}

// Tải và cập nhật toàn bộ Dashboard theo dữ liệu THỰC TẾ
function loadDashboardData() {
    const profiles = getRealProfiles();
    majorList = getStoredMajors();

    // 1. Thống kê tổng số hồ sơ nhận thực tế
    const totalCount = profiles.length;
    document.getElementById("totalProfiles").innerText = totalCount;

    // 2. Tính số lượng đếm thực tế theo từng ngành
    let totalQuota = 0;
    let totalApprovedCount = 0;
    let pendingCount = 0;
    let rejectedCount = 0;

    profiles.forEach(p => {
        if (p.status === "Đã duyệt") totalApprovedCount++;
        else if (p.status === "Chờ duyệt") pendingCount++;
        else if (p.status === "Từ chối") rejectedCount++;
    });

    majorList.forEach(m => {
        const approvedForMajor = profiles.filter(p => p.major.toUpperCase() === m.code.toUpperCase() && p.status === "Đã duyệt").length;
        m.approved = approvedForMajor;
        totalQuota += m.quota;
    });

    const remainingCount = Math.max(0, totalQuota - totalApprovedCount);
    document.getElementById("remainingSlots").innerText = `${remainingCount} / ${totalQuota}`;

    const virtualRateCalc = totalCount > 0 ? ((rejectedCount / totalCount) * 100).toFixed(1) : 0;
    document.getElementById("virtualRate").innerText = `${virtualRateCalc}%`;

    // 3. Vẽ biểu đồ
    renderCharts(profiles, majorList, totalApprovedCount, pendingCount, rejectedCount);

    // 4. Render bảng ngành học
    renderMajorTable();
}

// Khởi tạo & vẽ biểu đồ Chart.js
function renderCharts(profiles, majors, approved, pending, rejected) {
    const majorLabels = majors.map(m => m.code);
    const majorCounts = majors.map(m => {
        return profiles.filter(p => p.major.toUpperCase() === m.code.toUpperCase()).length;
    });

    const ctxMajor = document.getElementById('majorChart').getContext('2d');
    if (majorChartInstance) majorChartInstance.destroy();

    majorChartInstance = new Chart(ctxMajor, {
        type: 'bar',
        data: {
            labels: majorLabels,
            datasets: [{
                label: 'Số hồ sơ đăng ký thực tế',
                data: majorCounts,
                backgroundColor: '#1a4d8c',
                borderRadius: 4
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: { stepSize: 1 }
                }
            }
        }
    });

    const ctxStatus = document.getElementById('statusChart').getContext('2d');
    if (statusChartInstance) statusChartInstance.destroy();

    statusChartInstance = new Chart(ctxStatus, {
        type: 'doughnut',
        data: {
            labels: ['Đã duyệt', 'Chờ duyệt', 'Từ chối / Ảo'],
            datasets: [{
                data: [approved, pending, rejected],
                backgroundColor: ['#00b894', '#ffeaa7', '#d63031']
            }]
        },
        options: { responsive: true }
    });
}

// Render bảng quản lý ngành & điểm sàn
function renderMajorTable() {
    const tbody = document.getElementById("majorTableBody");
    if (!tbody) return;
    tbody.innerHTML = "";

    majorList.forEach((item, index) => {
        const tr = document.createElement("tr");
        tr.style.cursor = "pointer";
        tr.title = "Nhấp vào dòng này để điền dữ liệu lên form sửa";
        tr.innerHTML = `
            <td><strong style="color: var(--primary-color);">${item.code}</strong> ✏️</td>
            <td>${item.name}</td>
            <td>${item.quota}</td>
            <td><span class="text-success"><strong>${item.approved || 0}</strong></span></td>
            <td><strong style="color: #d63031;">${item.benchmark} điểm</strong></td>
            <td onclick="event.stopPropagation();">
                <button class="btn-primary btn-sm" style="margin-right: 5px; padding: 4px 8px;" onclick="selectMajorToEdit(${index})">Sửa</button>
                <button class="btn-danger btn-sm" style="padding: 4px 8px;" onclick="deleteMajor(${index})">Xóa</button>
            </td>
        `;

        // Sự kiện nhấp trực tiếp vào dòng để truyền dữ liệu lên form trên
        tr.onclick = () => selectMajorToEdit(index);

        tbody.appendChild(tr);
    });
}

// CHỨC NĂNG: TRUYỀN DỮ LIỆU TỪ BẢNG LÊN FORM CẬP NHẬT TRÊN
function selectMajorToEdit(index) {
    const item = majorList[index];
    if (!item) return;

    document.getElementById("newMajorCode").value = item.code;
    document.getElementById("newMajorName").value = item.name;
    document.getElementById("newMajorQuota").value = item.quota;
    document.getElementById("newBenchmark").value = item.benchmark;

    // Focus vào ô Mã ngành và cuộn nhẹ lên form nếu cần
    const codeInput = document.getElementById("newMajorCode");
    codeInput.focus();
    codeInput.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

// Thêm / Cập nhật cấu hình ngành học
function addMajorConfig() {
    const code = document.getElementById("newMajorCode").value.trim().toUpperCase();
    const name = document.getElementById("newMajorName").value.trim();
    const quota = parseInt(document.getElementById("newMajorQuota").value);
    const benchmark = parseFloat(document.getElementById("newBenchmark").value);

    if (!code || !name || isNaN(quota) || isNaN(benchmark)) {
        alert("Vui lòng nhập đầy đủ và chính xác thông tin ngành, chỉ tiêu và điểm sàn!");
        return;
    }

    const existingIndex = majorList.findIndex(m => m.code.toUpperCase() === code);
    if (existingIndex !== -1) {
        majorList[existingIndex].name = name;
        majorList[existingIndex].quota = quota;
        majorList[existingIndex].benchmark = benchmark;
        alert(`Đã cập nhật chỉ tiêu & điểm sàn cho ngành ${code}`);
    } else {
        majorList.push({ code, name, quota, approved: 0, benchmark });
        alert(`Đã thêm ngành mới: ${name}`);
    }

    saveMajors(majorList);

    document.getElementById("newMajorCode").value = "";
    document.getElementById("newMajorName").value = "";
    document.getElementById("newMajorQuota").value = "";
    document.getElementById("newBenchmark").value = "";

    loadDashboardData();
}

function deleteMajor(index) {
    if (confirm("Bạn có chắc chắn muốn xóa ngành này khỏi danh mục tuyển sinh?")) {
        majorList.splice(index, 1);
        saveMajors(majorList);
        loadDashboardData();
    }
}