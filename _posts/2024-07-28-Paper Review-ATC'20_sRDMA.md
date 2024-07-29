---
title: "[Paper Review] ATC'20 sRDMA"
categories:
  - Paper
tags:
  - Network
  - FPGA
---
# sRDMA – Efficient NIC-based Authentication and Encryption for Remote Direct Memory Access
<br>
>Due to copyright issues, I do not include `Figures` that are embedded in the paper :(
{: .prompt-warning }  

> This article is being edited
{: .prompt-danger }  
 
## Introduction
---

앞서 어제와 그제 논문 리뷰에서 모두 RDMA 개념이 나왔었죠ㅋㅋ 네 맞아요.. 제가 RDMA로 난리치고 있습니다... 아 뭐 RDMA만 리뷰할 건 아니니 걱정 말아주세요..!
sRDMA는 네트워크 공격자(Adversaries)가 RDMA 기술의 취약점을 이용한 공격을 방지하고자 암호화를 제공하는 프로토콜 입니다!!  

<br>
### Backgrounds

RDMA 기술 자체에는 암호 관련 기술이 하나도 적용이 되어있지 않습니다. 그러니 만약 공격자가 RDMA를 컨트롤할 수 있는 권한을 얻게 되거나 도청이 되게 된다면 손 쓸 도리가 없다는 것이죠. 결국 격리(isolation) 말고는 답이 없다 이겁니다.  
그럼 L5 수준에서 암호화 하면 되는거 아닌가? 싶지만 요건 RDMA가 단방향일 수도 있어서 ㄴㄴ 의미가 없다는 것이에요! 그리고 버퍼를 또 써야하고, CPU로 해독하고.... 그럼 RDMA를 쓸 필요가 없잖아요? 그래서 이 연구는 대칭 암호화를 사용한 보안 RDMA를 말하고 있습니다.  
그리고 SRC QP(Secure Reliable Connection Queue Pair,,,ㄹㅇ별다줄;;)을 설계했다고 하네요.  

<br><br>

### 그래서 RDMA가 뭔데?

RDMA는 DMA(Direct Memory Access)에 R(Remote) 한 글자 붙은 건데요, CPU 개입 없이 NIC가 곧바로 메모리에 접근하도록 하는 기술입니다. 그리고 몇가지 네트워크 아키텍쳐가 있는데요..!  
1)  InfiniBand : RDMA를 가능하게 하는 완전한 네트워크 아키텍쳐 (하드웨어 포함)  
2)  RoCE : 이더넷에서 RDMA를 가능하게 해주는 친구
3) iWARP : TCP/IP로 RDMA로 가능하게 해주는 친구  
그리고 sRDMA 이 모든 것에 다 적용할 수 있다고 합니다.  

그 중에서 infiniBand(이하 IBA, A는 Architecture)는 여러 전송 유형이 있는데, 그 중에서 R/W가 모두 가능한 Reliable Connection(RC)만 고려했다고 하네요. RC 전송 유형에서 Queue Pair(이하 QP)를 설정하고 하나의 RC QP는 다른 어댑터와 통신할 수 없으며, RDMA-capable NICs(이하 RNIC)에서 고유하게 식별하는 QP number(이하 QPN)이 할당된다고 합니다.  
RC 전송은 신뢰성을 보장하기 위해서 패킷이 잘 전달되었는지 확인 응답을 해줘야하고, 무결성 보장을 위해 두 개의 체크섬을 넣고, 각 패킷에 패킷 순서 번호(이하 PSN)을 넣어 패킷을 카운트해야 한다고 합니다. 다시 말하면 엔드포인트에서 순서대로 전달하고 중복이나 손실 패킷을 감지할 수 있도록 한다는 것이죠.  

그리고 IBA에는 메모리 보호 매커니즘이 있다고 하는데요
1) 메모리 영역이 할당되면 RNIC은 액세스 키를 발급해 RDMA 요청 시 키를 증명해야 합니다.
2) 하나의 보호 도메인(이하 PD)에서 생성된 QP 연결은 다른 PD에서 할당된 메모리에 액세스할 수 없게 하여 메모리의 무단 혹은 실수에 의한 남용으로부터 보호합니다.
3) 메모리 윈도우는 원격 QP가 메모리 영역 내 다른 액세스 권한을 가지게 하고, 메모리의 일부분만 액세스하도록 하여 메모리 보호를 확장합니다.

<br><br>
아,, 뭔 놈의 "이하"가 많냐구요..? 죄송합니다...
<br>
<br>
## Summary
---

### Problems

위의 IBA 보호 매커니즘에도 불구하고 안전한 통신을 보장하기에는 어려움이 있습니다. 도청으로부터 데이터를 숨겨야하기 때문이죠. 동시에 성능도 잡아야 합니다!

<br>
### Threat Model

##### Location
공격자는 네트워크 안이면 뭐 아무데나 서식할 수 있읍니다. 악성 클라우드 제공자일 수도 있고, 악성 관리자 일 수도 있고, 중간 장치 내 일 수도 있고, 엔드 호스트 일 수도 있고.... 뭐 다 됩니다. 근데 그래도 RNIC 연구하는건데 RNIC 자체랑 CPU-RNIC 간 버스는 봐주자고요.  

##### Capabilities
도청도 되고 통신 조작도 되고 IB나 헤더 정보나 뭐 이런거 다 알 수 있고 바꿀 수도 있읍니다. 거의 전지전능하다 생각해요. QPN이나 아까 위에서 말한 키이고 뭐고 다 바꿀 수 있읍니다.

##### Cryptography
그래도 공격자는 얘가 난수인지 아닌지 구별은 못한다고 하네요.

<br><br>
### Design

IBA 기반으로 사알짝 바꿔서 새로운 통신 유형을 만들어보아요!
1) QP에 대한 대칭 키 초기화 추가
2) 메세지 인증 코드(이하 MAC)를 포함한, 패킷 내용의 무결성을 제공하는 새로운 보안 전송 헤더(이하 STH)

#### SRC QP

SRC QP로 먼저 STH를 모든 패킷에 포함하여 만들어간다고 하네요. 그래서 STH 길이 지정을 위해 패킷 헤더의 7개 예약 비트 중 3개를 쓴다고 합니다.  

##### Reusing PSN as a Per-Packet Nonce
sRDMA는 각 패킷의  MAC 계산에 고유한 Nonce를 포함해 replay 공격..?을 방지한다고 합니다. Nonce는 암호화 특성상 재사용되면 안된다고 하네요. 그런데 이 Nonce를 그냥 단순하게 평문으로 보내면 64비트 이상의 오버헤드가 생겨 메모리에 저장하는데 또 부담이 된다고 합니다. 그래서 PSN을 Nonce로 사용합니다. 그리고 PSN 카운터를 64비트로 확장하고 이걸 재사용해서 각 Nonce에는 40비트의 오버헤드만 추가합니다. 그런다고 PSN 크기가 바뀌는 것은 아니고 sRDMA가 헤더의 24비트 PSN만으로 사용된 64비트 Nonce를 추론할 수 있다고 합니다. 또 이렇게 해도 재사용은 3000년 후에나 생긴다고 합니다.  

##### Header Authentication
$$ mac_{hdr} = MAC_{K_{A,B}}(nonce_{A->B}||RH||BTH)$$
헤더 인증을 위해 대칭 키로 MAC를 계산합니다.  
- RH : 어댑터 포트 주소를 정의하는 라우팅 헤더  
- BTH : 목적지 QPN을 포함하는 기본 전송 헤더  
수신 노드의 RNIC은 각 패킷마다 MAC을 재계산하고 STH에 추가된 MAC과 비교합니다.  

##### Packet Authentication and Encryption
아까 공격 모델에서 말한대로 RNIC은 공격 안받는 곳이니 호스트는 개꿀을 외치며 모든 암호화 작업을 RNIC으로 오프로드할 수 있겠죵..?  
그래서 AEAD(Authenticated Encryption with Associated Data)를 사용해 Payload의 비밀성과 무결성을 확보하고, 인증 태그를 STH의 MAC 필드로 전송합니다.  

##### PD-Level Protection


##### Extended Memory Protection



##### Sub-Delegation of Access to Memory



#### Implementation

sRDMA는 C++로 구현되었고, libibverbs, librdmacm, Openssl 1.1.1a, libev 등의 라이브러리를 사용했다고 합니다. 그리고 SmartNIC을 사용했고, RoCEv2로 RDMA를 지원하며 암호화 가속이 가능하다고 합니다. 즉, sRDMA는 SmartNIC을 통해 양방향으로 전송될 수 있습니다. `Figure 4`에 ㅁ그 구조가 나와있는데, Initiator, SmartNIC, Target으로 구성되네요.


<br><br>
## Review
---


<br><br>
## Strength & Weakness
---


<br><br>

Thanks!!