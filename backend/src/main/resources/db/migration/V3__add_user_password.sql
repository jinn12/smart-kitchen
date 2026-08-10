-- 인증: 비밀번호 해시 컬럼 추가 (D-018)
ALTER TABLE app_user ADD COLUMN password_hash VARCHAR(100) NOT NULL;