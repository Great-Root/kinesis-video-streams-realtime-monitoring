다음은 **Frontend Hosting 모듈**의 `README.md`입니다. 기존 내용을 참고하여 주요 구성 요소, 파일 구조, 변수 및 출력값을 정리했습니다.

---

# 📌 Frontend Hosting 모듈

## 📖 소개

`frontend-hosting` 모듈은 **AWS S3와 CloudFront를 활용하여 정적 웹사이트를 배포**하는 인프라를 자동화하는 Terraform 모듈입니다.  
또한, **WAF 및 Geo 기반 접근제어**를 적용할 수 있도록 설계되었습니다.

---

## 🏗 주요 기능

- **S3 버킷 자동 생성** (프로젝트명 + 환경 + 랜덤 4글자 Suffix 포함)
- **CloudFront 배포 자동 설정** (HTTPS 지원, 캐싱 정책 적용)
- **AWS WAF 연동 가능** (IP 기반 접근제어 설정 가능)
- **Geo 기반 접근제어 지원** (특정 국가 접근 허용 또는 차단 가능)

---

## 📂 파일 구조

```
📂 modules/frontend-hosting
 ┣ 📜 main.tf            # S3, CloudFront 및 WAF 리소스 정의
 ┣ 📜 variables.tf       # 모듈에서 사용되는 변수 정의
 ┣ 📜 outputs.tf         # 모듈에서 생성된 리소스 출력
 ┣ 📜 README.md          # 모듈 설명 문서
```

---

## 🔧 주요 변수 (`variables.tf`)

| 변수명                      | 설명                                         | 예제 값              |
| --------------------------- | -------------------------------------------- | -------------------- |
| `project_name`              | 프로젝트 이름                                | `"my-video-project"` |
| `region`                    | AWS 리전                                     | `"ap-northeast-1"`   |
| `environment`               | 환경 (`dev`, `staging`, `prod`)              | `"dev"`              |
| `price_class`               | CloudFront 가격 클래스                       | `"PriceClass_100"`   |
| `enable_waf`                | WAF 활성화 여부                              | `true`               |
| `waf_allowed_cidrs`         | WAF에서 허용할 IP 목록                       | `["203.0.113.0/24"]` |
| `enable_geo_restriction`    | Geo 기반 접근제어 활성화 여부                | `true`               |
| `geo_restriction_type`      | Geo 제한 방식 (`whitelist` 또는 `blacklist`) | `"blacklist"`        |
| `geo_restriction_locations` | 접근을 제한할 국가 목록                      | `["CN", "RU"]`       |

---

## 📤 출력 값 (`outputs.tf`)

| 출력 변수명              | 설명                                    |
| ------------------------ | --------------------------------------- |
| `s3_bucket_name`         | 정적 웹사이트를 호스팅하는 S3 버킷 이름 |
| `cloudfront_domain_name` | CloudFront 배포 도메인 (CDN)            |
| `website_url`            | 정적 웹사이트 URL                       |
| `waf_web_acl_id`         | WAF WebACL ID (WAF 활성화 시)           |
| `geo_restriction_status` | Geo 기반 접근제어 설정 상태             |

---

## 🏗 배포 후 확인 사항

1. `terraform apply` 후 생성된 **CloudFront 도메인**을 확인하세요.
2. **WAF 설정**이 올바르게 적용되었는지 AWS WAF 콘솔에서 확인하세요.
3. **Geo 기반 접근제어 설정**이 적용되었는지 CloudFront Restriction 설정을 확인하세요.

---

## 🛠️ 추가 설정

- **S3에 업로드 자동화**
  ```sh
  aws s3 sync ./build s3://$(terraform output s3_bucket_name) --delete
  ```
- **CloudFront 캐시 무효화**
  ```sh
  aws cloudfront create-invalidation --distribution-id <distribution_id> --paths "/*"
  ```

✅ **이 모듈을 사용하면 AWS에서 안전하고 효율적인 정적 웹사이트 배포 환경을 자동으로 구성할 수 있습니다!** 🚀
