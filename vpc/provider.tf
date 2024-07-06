/* 
terraform으로 정의할 infrastructure의 유형을 지정한다.
terraform으로 aws의 자원들을 사용할 것이기 때문에 aws로 지정
만약 gcp를 사용한다면 google로 지정하여 사용하면 된다.
*/
provider "aws" {
  region = "ap-northeast-2"
}