// shared/js/api-config.js
const API_BASE_URL = "http://localhost:8080/api";

// API từ Huy
const API_HUY = {
    LOGIN: `${API_BASE_URL}/auth/login`,
    APPROVE_PROFILE: `${API_BASE_URL}/admin/profiles/approve`,
};

// API từ Khang
const API_KHANG = {
    STATISTICS: `${API_BASE_URL}/admin/stats`,
    FILTER_BENCHMARK: `${API_BASE_URL}/admin/benchmark`,
};