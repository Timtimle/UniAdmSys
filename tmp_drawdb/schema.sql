-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.truong_dh (
  ma_truong bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ten_truong character varying NOT NULL,
  dia_chi character varying,
  website character varying,
  tinh_thanh character varying,
  loai_truong character varying,
  nam_thanh_lap integer,
  mo_ta text,
  ma_tuyen_sinh character varying,
  CONSTRAINT truong_dh_pkey PRIMARY KEY (ma_truong)
);
CREATE TABLE public.nganh (
  ma_nganh character varying NOT NULL,
  ma_truong bigint NOT NULL,
  ten_nganh text NOT NULL,
  linh_vuc character varying,
  mo_ta text,
  thoi_gian_dao_tao integer,
  danh_muc_nganh_id bigint,
  ma_nganh_tuyen_sinh character varying,
  nam smallint,
  source_url text,
  CONSTRAINT nganh_pkey PRIMARY KEY (ma_nganh),
  CONSTRAINT nganh_ma_truong_fkey FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_truong),
  CONSTRAINT nganh_danh_muc_nganh_id_fkey FOREIGN KEY (danh_muc_nganh_id) REFERENCES public.danh_muc_nganh(id)
);
CREATE TABLE public.phuong_thuc_xet_tuyen (
  ma_pt bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ten_phuong_thuc character varying NOT NULL,
  mo_ta text,
  ma_phuong_thuc character varying,
  ma_truong character varying,
  nam smallint,
  source_url text,
  created_at timestamp without time zone DEFAULT now(),
  loai_phuong_thuc character varying,
  ma_ky_thi character varying,
  CONSTRAINT phuong_thuc_xet_tuyen_pkey PRIMARY KEY (ma_pt),
  CONSTRAINT ptxt_ma_truong_fkey FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh),
  CONSTRAINT phuong_thuc_ma_ky_thi_fkey FOREIGN KEY (ma_ky_thi) REFERENCES public.ky_thi_danh_gia(ma_ky_thi)
);
CREATE TABLE public.diem_chuan (
  id bigint NOT NULL DEFAULT nextval('diem_chuan_id_seq'::regclass),
  ma_truong character varying NOT NULL,
  ma_nganh character varying NOT NULL,
  nam integer NOT NULL,
  phuong_thuc text,
  to_hop text,
  diem numeric,
  ghi_chu text,
  created_at timestamp without time zone DEFAULT now(),
  source_url text,
  loai_diem character varying,
  ma_ky_thi character varying,
  thang_diem numeric,
  CONSTRAINT diem_chuan_pkey PRIMARY KEY (id),
  CONSTRAINT fk_diem_chuan_truong FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh),
  CONSTRAINT fk_diem_chuan_nganh FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh),
  CONSTRAINT diem_chuan_ma_ky_thi_fkey FOREIGN KEY (ma_ky_thi) REFERENCES public.ky_thi_danh_gia(ma_ky_thi)
);
CREATE TABLE public.hoc_phi (
  id bigint NOT NULL DEFAULT nextval('hoc_phi_id_seq'::regclass),
  ma_truong character varying,
  ma_nganh character varying,
  nam integer,
  chuong_trinh character varying,
  muc_hoc_phi numeric,
  ghi_chu text,
  created_at timestamp without time zone DEFAULT now(),
  nam_hoc character varying,
  hoc_phi_min bigint,
  hoc_phi_max bigint,
  don_vi character varying DEFAULT 'VND/năm'::character varying,
  source_url text,
  trang_thai character varying DEFAULT 'chua_xac_minh'::character varying,
  source_type character varying,
  CONSTRAINT hoc_phi_pkey PRIMARY KEY (id),
  CONSTRAINT fk_hoc_phi_truong FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh)
);
CREATE TABLE public.knowledge_base (
  id bigint NOT NULL DEFAULT nextval('knowledge_base_id_seq'::regclass),
  title text NOT NULL,
  content text NOT NULL,
  category character varying,
  source text,
  metadata jsonb,
  embedding USER-DEFINED,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT knowledge_base_pkey PRIMARY KEY (id)
);
CREATE TABLE public.ai_chat_history (
  id bigint NOT NULL DEFAULT nextval('ai_chat_history_id_seq'::regclass),
  user_id bigint,
  question text,
  answer text,
  source_documents jsonb,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT ai_chat_history_pkey PRIMARY KEY (id)
);
CREATE TABLE public.danh_muc_nganh (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_nganh_bo character varying NOT NULL UNIQUE,
  ten_nganh text NOT NULL,
  linh_vuc text,
  trinh_do character varying DEFAULT 'Đại học'::character varying,
  source_url text,
  CONSTRAINT danh_muc_nganh_pkey PRIMARY KEY (id)
);
CREATE TABLE public.to_hop_xet_tuyen (
  ma_to_hop character varying NOT NULL,
  ten_to_hop text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT to_hop_xet_tuyen_pkey PRIMARY KEY (ma_to_hop)
);
CREATE TABLE public.nganh_to_hop_xet_tuyen (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_truong character varying NOT NULL,
  ma_nganh character varying NOT NULL,
  nam smallint NOT NULL,
  ma_to_hop character varying NOT NULL,
  phuong_thuc text,
  source_url text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT nganh_to_hop_xet_tuyen_pkey PRIMARY KEY (id),
  CONSTRAINT nganh_to_hop_nganh_fkey FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh),
  CONSTRAINT nganh_to_hop_ma_to_hop_fkey FOREIGN KEY (ma_to_hop) REFERENCES public.to_hop_xet_tuyen(ma_to_hop),
  CONSTRAINT fk_nganh_to_hop_truong FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh)
);
CREATE TABLE public.chi_tieu_tuyen_sinh (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_truong character varying,
  nam smallint,
  cap_do character varying DEFAULT 'truong'::character varying CHECK (cap_do::text = ANY (ARRAY['truong'::character varying, 'nganh'::character varying]::text[])),
  chi_tieu integer,
  chi_tieu_min integer,
  chi_tieu_max integer,
  he_dao_tao text DEFAULT 'Đại học chính quy'::text,
  trang_thai character varying DEFAULT 'chua_xac_minh'::character varying,
  ghi_chu text,
  source_type character varying,
  source_url text,
  created_at timestamp without time zone DEFAULT now(),
  ma_nganh character varying,
  CONSTRAINT chi_tieu_tuyen_sinh_pkey PRIMARY KEY (id),
  CONSTRAINT fk_chi_tieu_truong FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh),
  CONSTRAINT fk_chi_tieu_nganh FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh)
);
CREATE TABLE public.thi_sinh (
  ma_thi_sinh bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid UNIQUE,
  cccd character varying UNIQUE,
  ho_ten character varying NOT NULL,
  ngay_sinh date,
  gioi_tinh character varying,
  tinh_thanh character varying,
  so_dien_thoai character varying,
  email character varying,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT thi_sinh_pkey PRIMARY KEY (ma_thi_sinh)
);
CREATE TABLE public.diem_thi (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_thi_sinh bigint NOT NULL,
  nam smallint NOT NULL,
  mon_thi character varying NOT NULL,
  diem numeric CHECK (diem IS NULL OR diem >= 0::numeric AND diem <= 10::numeric),
  created_at timestamp without time zone DEFAULT now(),
  ma_mon character varying,
  CONSTRAINT diem_thi_pkey PRIMARY KEY (id),
  CONSTRAINT diem_thi_ma_mon_fkey FOREIGN KEY (ma_mon) REFERENCES public.mon_thi(ma_mon),
  CONSTRAINT diem_thi_ma_thi_sinh_fkey FOREIGN KEY (ma_thi_sinh) REFERENCES public.thi_sinh(ma_thi_sinh)
);
CREATE TABLE public.nguyen_vong (
  ma_nv bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_thi_sinh bigint NOT NULL,
  ma_nganh character varying NOT NULL,
  nam smallint NOT NULL DEFAULT 2025,
  ma_phuong_thuc character varying,
  ma_to_hop character varying,
  thu_tu_nguyen_vong integer NOT NULL CHECK (thu_tu_nguyen_vong > 0),
  created_at timestamp without time zone DEFAULT now(),
  ma_ho_so bigint,
  CONSTRAINT nguyen_vong_pkey PRIMARY KEY (ma_nv),
  CONSTRAINT nguyen_vong_ma_thi_sinh_fkey FOREIGN KEY (ma_thi_sinh) REFERENCES public.thi_sinh(ma_thi_sinh),
  CONSTRAINT nguyen_vong_ma_nganh_fkey FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh),
  CONSTRAINT nguyen_vong_ma_to_hop_fkey FOREIGN KEY (ma_to_hop) REFERENCES public.to_hop_xet_tuyen(ma_to_hop),
  CONSTRAINT nguyen_vong_ma_ho_so_fkey FOREIGN KEY (ma_ho_so) REFERENCES public.ho_so_xet_tuyen(ma_ho_so),
  CONSTRAINT nguyen_vong_ma_phuong_thuc_fkey FOREIGN KEY (ma_phuong_thuc) REFERENCES public.phuong_thuc_xet_tuyen(ma_phuong_thuc)
);
CREATE TABLE public.ket_qua_xet_tuyen (
  ma_kq bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_thi_sinh bigint NOT NULL,
  ma_nv bigint NOT NULL,
  diem_xet_tuyen numeric,
  ghi_chu text,
  created_at timestamp without time zone DEFAULT now(),
  diem_chuan_id bigint,
  diem_chuan_ap_dung numeric,
  trang_thai character varying DEFAULT 'cho_xet'::character varying CHECK (trang_thai::text = ANY (ARRAY['cho_xet'::character varying, 'trung_tuyen'::character varying, 'khong_dat'::character varying, 'khong_xet'::character varying, 'thieu_du_lieu'::character varying]::text[])),
  xet_tuyen_thang boolean NOT NULL DEFAULT false,
  ly_do text,
  updated_at timestamp with time zone DEFAULT now(),
  nguon_diem character varying DEFAULT 'thi_thpt'::character varying,
  quy_tac_hoc_ba_id bigint,
  CONSTRAINT ket_qua_xet_tuyen_pkey PRIMARY KEY (ma_kq),
  CONSTRAINT ket_qua_quy_tac_hoc_ba_id_fkey FOREIGN KEY (quy_tac_hoc_ba_id) REFERENCES public.quy_tac_xet_hoc_ba(id),
  CONSTRAINT ket_qua_xet_tuyen_ma_thi_sinh_fkey FOREIGN KEY (ma_thi_sinh) REFERENCES public.thi_sinh(ma_thi_sinh),
  CONSTRAINT ket_qua_xet_tuyen_ma_nv_fkey FOREIGN KEY (ma_nv) REFERENCES public.nguyen_vong(ma_nv),
  CONSTRAINT ket_qua_diem_chuan_id_fkey FOREIGN KEY (diem_chuan_id) REFERENCES public.diem_chuan(id)
);
CREATE TABLE public.can_bo (
  ma_can_bo bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid UNIQUE,
  ten_dang_nhap character varying NOT NULL UNIQUE,
  ho_ten character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  so_dien_thoai character varying,
  don_vi character varying,
  chuc_vu character varying,
  vai_tro character varying NOT NULL DEFAULT 'can_bo'::character varying,
  trang_thai character varying NOT NULL DEFAULT 'hoat_dong'::character varying,
  lan_dang_nhap_cuoi timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT can_bo_pkey PRIMARY KEY (ma_can_bo)
);
CREATE TABLE public.thanh_tich_chung_chi (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_thi_sinh bigint NOT NULL,
  nhom character varying NOT NULL CHECK (nhom::text = ANY (ARRAY['thanh_tich'::character varying, 'chung_chi'::character varying]::text[])),
  loai character varying NOT NULL,
  ten text NOT NULL,
  mon_linh_vuc character varying,
  cap_giai character varying,
  thu_hang_giai smallint,
  diem_so numeric,
  thang_diem character varying,
  don_vi_cap character varying,
  ngay_cap date,
  ngay_het_han date,
  minh_chung_url text,
  trang_thai_xac_minh character varying NOT NULL DEFAULT 'chua_xac_minh'::character varying CHECK (trang_thai_xac_minh::text = ANY (ARRAY['chua_xac_minh'::character varying, 'da_xac_minh'::character varying, 'tu_choi'::character varying]::text[])),
  ma_can_bo_xac_minh bigint,
  xac_minh_luc timestamp with time zone,
  ghi_chu text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT thanh_tich_chung_chi_pkey PRIMARY KEY (id),
  CONSTRAINT thanh_tich_chung_chi_ma_thi_sinh_fkey FOREIGN KEY (ma_thi_sinh) REFERENCES public.thi_sinh(ma_thi_sinh),
  CONSTRAINT thanh_tich_chung_chi_ma_can_bo_xac_minh_fkey FOREIGN KEY (ma_can_bo_xac_minh) REFERENCES public.can_bo(ma_can_bo)
);
CREATE TABLE public.dieu_kien_xet_tuyen_thang (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_truong character varying NOT NULL,
  nam smallint NOT NULL DEFAULT 2025,
  ma_nganh character varying,
  ma_phuong_thuc character varying,
  loai_thanh_tich character varying NOT NULL,
  mon_linh_vuc character varying,
  giai_toi_da smallint,
  xet_tuyen_thang boolean NOT NULL DEFAULT true,
  uu_tien_xet_tuyen boolean NOT NULL DEFAULT false,
  ghi_chu text,
  source_url text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT dieu_kien_xet_tuyen_thang_pkey PRIMARY KEY (id),
  CONSTRAINT dieu_kien_xet_tuyen_thang_ma_nganh_fkey FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh),
  CONSTRAINT dieu_kien_xet_tuyen_thang_ma_truong_fkey FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh),
  CONSTRAINT dieu_kien_xet_tuyen_thang_ma_pt_fkey FOREIGN KEY (ma_phuong_thuc) REFERENCES public.phuong_thuc_xet_tuyen(ma_phuong_thuc)
);
CREATE TABLE public.quy_doi_chung_chi (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_truong character varying NOT NULL,
  nam smallint NOT NULL DEFAULT 2025,
  ma_nganh character varying,
  ma_phuong_thuc character varying,
  loai_chung_chi character varying NOT NULL,
  diem_tu numeric NOT NULL,
  diem_den numeric,
  diem_quy_doi numeric NOT NULL,
  thang_diem_quy_doi character varying DEFAULT '10'::character varying,
  ghi_chu text,
  source_url text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quy_doi_chung_chi_pkey PRIMARY KEY (id),
  CONSTRAINT quy_doi_chung_chi_ma_nganh_fkey FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh),
  CONSTRAINT quy_doi_chung_chi_ma_truong_fkey FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh),
  CONSTRAINT quy_doi_chung_chi_ma_pt_fkey FOREIGN KEY (ma_phuong_thuc) REFERENCES public.phuong_thuc_xet_tuyen(ma_phuong_thuc)
);
CREATE TABLE public.nguong_dau_vao (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_truong character varying NOT NULL,
  nam smallint NOT NULL DEFAULT 2025,
  ma_nganh character varying,
  ma_phuong_thuc character varying,
  trang_thai character varying DEFAULT 'chua_xac_minh'::character varying,
  ghi_chu text,
  source_url text,
  created_at timestamp with time zone DEFAULT now(),
  diem_san numeric,
  CONSTRAINT nguong_dau_vao_pkey PRIMARY KEY (id),
  CONSTRAINT nguong_dau_vao_ma_truong_fkey FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh),
  CONSTRAINT nguong_dau_vao_ma_nganh_fkey FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh),
  CONSTRAINT nguong_dau_vao_ma_phuong_thuc_fkey FOREIGN KEY (ma_phuong_thuc) REFERENCES public.phuong_thuc_xet_tuyen(ma_phuong_thuc)
);
CREATE TABLE public.mon_thi (
  ma_mon character varying NOT NULL,
  ten_mon character varying NOT NULL UNIQUE,
  CONSTRAINT mon_thi_pkey PRIMARY KEY (ma_mon)
);
CREATE TABLE public.ho_so_xet_tuyen (
  ma_ho_so bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_thi_sinh bigint NOT NULL,
  nam smallint NOT NULL DEFAULT 2025,
  trang_thai character varying NOT NULL DEFAULT 'nhap'::character varying CHECK (trang_thai::text = ANY (ARRAY['nhap'::character varying, 'da_nop'::character varying, 'dang_duyet'::character varying, 'yeu_cau_bo_sung'::character varying, 'hoan_tat'::character varying]::text[])),
  ma_can_bo_phu_trach bigint,
  ngay_nop timestamp with time zone,
  ngay_duyet timestamp with time zone,
  ghi_chu text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  ket_qua_xet_tuyen character varying DEFAULT 'chua_xet'::character varying CHECK (ket_qua_xet_tuyen::text = ANY (ARRAY['chua_xet'::character varying, 'trung_tuyen'::character varying, 'khong_trung_tuyen'::character varying, 'thieu_du_lieu'::character varying]::text[])),
  ma_nv_trung_tuyen bigint,
  xet_tuyen_luc timestamp with time zone,
  CONSTRAINT ho_so_xet_tuyen_pkey PRIMARY KEY (ma_ho_so),
  CONSTRAINT ho_so_xet_tuyen_ma_thi_sinh_fkey FOREIGN KEY (ma_thi_sinh) REFERENCES public.thi_sinh(ma_thi_sinh),
  CONSTRAINT ho_so_xet_tuyen_ma_can_bo_phu_trach_fkey FOREIGN KEY (ma_can_bo_phu_trach) REFERENCES public.can_bo(ma_can_bo),
  CONSTRAINT ho_so_ma_nv_trung_tuyen_fkey FOREIGN KEY (ma_nv_trung_tuyen) REFERENCES public.nguyen_vong(ma_nv)
);
CREATE TABLE public.hoc_ba (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_thi_sinh bigint NOT NULL,
  lop smallint NOT NULL CHECK (lop = ANY (ARRAY[10, 11, 12])),
  hoc_ky smallint NOT NULL CHECK (hoc_ky = ANY (ARRAY[1, 2])),
  ma_mon character varying NOT NULL,
  diem_tb numeric NOT NULL CHECK (diem_tb >= 0::numeric AND diem_tb <= 10::numeric),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT hoc_ba_pkey PRIMARY KEY (id),
  CONSTRAINT hoc_ba_ma_thi_sinh_fkey FOREIGN KEY (ma_thi_sinh) REFERENCES public.thi_sinh(ma_thi_sinh),
  CONSTRAINT hoc_ba_ma_mon_fkey FOREIGN KEY (ma_mon) REFERENCES public.mon_thi(ma_mon)
);
CREATE TABLE public.to_hop_mon (
  ma_to_hop character varying NOT NULL,
  ma_mon character varying NOT NULL,
  thu_tu smallint NOT NULL DEFAULT 1,
  CONSTRAINT to_hop_mon_pkey PRIMARY KEY (ma_to_hop, ma_mon),
  CONSTRAINT to_hop_mon_ma_to_hop_fkey FOREIGN KEY (ma_to_hop) REFERENCES public.to_hop_xet_tuyen(ma_to_hop),
  CONSTRAINT to_hop_mon_ma_mon_fkey FOREIGN KEY (ma_mon) REFERENCES public.mon_thi(ma_mon)
);
CREATE TABLE public.quy_tac_xet_hoc_ba (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_truong character varying NOT NULL,
  nam smallint NOT NULL DEFAULT 2025,
  ma_nganh character varying,
  ma_phuong_thuc character varying,
  ma_to_hop character varying,
  cach_tinh character varying NOT NULL CHECK (cach_tinh::text = ANY (ARRAY['lop12_ca_nam'::character varying, '5_hoc_ky'::character varying, '6_hoc_ky'::character varying]::text[])),
  diem_nguong numeric CHECK (diem_nguong IS NULL OR diem_nguong >= 0::numeric AND diem_nguong <= 30::numeric),
  diem_mon_toi_thieu numeric CHECK (diem_mon_toi_thieu IS NULL OR diem_mon_toi_thieu >= 0::numeric AND diem_mon_toi_thieu <= 10::numeric),
  ghi_chu text,
  source_url text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quy_tac_xet_hoc_ba_pkey PRIMARY KEY (id),
  CONSTRAINT quy_tac_xet_hoc_ba_ma_phuong_thuc_fkey FOREIGN KEY (ma_phuong_thuc) REFERENCES public.phuong_thuc_xet_tuyen(ma_phuong_thuc),
  CONSTRAINT quy_tac_xet_hoc_ba_ma_to_hop_fkey FOREIGN KEY (ma_to_hop) REFERENCES public.to_hop_xet_tuyen(ma_to_hop),
  CONSTRAINT quy_tac_xet_hoc_ba_ma_truong_fkey FOREIGN KEY (ma_truong) REFERENCES public.truong_dh(ma_tuyen_sinh),
  CONSTRAINT quy_tac_xet_hoc_ba_ma_nganh_fkey FOREIGN KEY (ma_nganh) REFERENCES public.nganh(ma_nganh)
);
CREATE TABLE public.ky_thi_danh_gia (
  ma_ky_thi character varying NOT NULL,
  ten_ky_thi text NOT NULL,
  don_vi_to_chuc text,
  nam smallint NOT NULL DEFAULT 2025,
  thang_diem numeric NOT NULL CHECK (thang_diem > 0::numeric),
  mo_ta text,
  source_url text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ky_thi_danh_gia_pkey PRIMARY KEY (ma_ky_thi)
);
CREATE TABLE public.ket_qua_ky_thi_danh_gia (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ma_thi_sinh bigint NOT NULL,
  ma_ky_thi character varying NOT NULL,
  nam smallint NOT NULL DEFAULT 2025,
  diem numeric NOT NULL CHECK (diem >= 0::numeric),
  trang_thai_xac_minh character varying NOT NULL DEFAULT 'da_xac_minh'::character varying CHECK (trang_thai_xac_minh::text = ANY (ARRAY['chua_xac_minh'::character varying, 'da_xac_minh'::character varying, 'tu_choi'::character varying]::text[])),
  ngay_thi date,
  so_bao_danh character varying,
  ghi_chu text,
  source_url text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ket_qua_ky_thi_danh_gia_pkey PRIMARY KEY (id),
  CONSTRAINT ket_qua_ky_thi_danh_gia_ma_thi_sinh_fkey FOREIGN KEY (ma_thi_sinh) REFERENCES public.thi_sinh(ma_thi_sinh),
  CONSTRAINT ket_qua_ky_thi_danh_gia_ma_ky_thi_fkey FOREIGN KEY (ma_ky_thi) REFERENCES public.ky_thi_danh_gia(ma_ky_thi)
);