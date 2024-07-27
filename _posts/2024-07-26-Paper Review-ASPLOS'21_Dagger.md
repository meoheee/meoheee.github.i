---
title: "[Paper Review] ASPLOS'21 Dagger"
categories:
  - Paper
tags:
  - Network
  - FPGA
---
# Dagger: Efficient and Fast RPCs in Cloud Microservices withNear-Memory Reconfigurable NICs
<br>
>Due to copyright issues, I do not include `Figures` that are embedded in the paper :(
{: .prompt-warning }  

> This article is being edited
{: .prompt-danger }  
 
## Introduction
---

### Backgrounds

만약 여러분의 학교가 평균 1000명이 매분마다 접속한다치고 이를 위한 서버가 1억짜리라고 해봅시다  
그런데 10000명이 수강신청날 몰려든다라고 해볼게요. 이를 위한 서버가 10억짜리라고 해봅시다  
그럼 우리 학교는 무슨 서버를 살까요? 맞아요 1억짜리에요  

이를 위해 클라우드 서비스를 사용하는데요, 이런 수강신청날을 위해 빠르고 쉽게 도커같은 컨테이너들을 띄워 유연한 확장성을 갖춰보자는 것이 마이크로서비스 입니다  
그래서 이 마이크로서비스는 Fine-grained 하고 (번역 못하겠음) 가벼운 프로토콜을 가지고 있죠. 또 모듈성과 오류 격리성도 얻을 수 있고요.
<br><br>
### Problems

근데 뭐가 문제이길래? 저자는 이런 마이크로서비스와 같은 경우 보통 가벼운 계산만 포함하니 네트워킹이 전체 지연 시간을 높은 비율로 잡아먹는거 아니냐? 라고 말하고 있습니다.  
마이크로서비스는 보통 RPC(원격 프로시저 호출)을 통해 통신하는데, 이 프레임워크가 성능에 상당한 오버헤드를 초래한다고 하거든요.  

통신 오버헤드에 대한 부분은 `Figure 3` 에서 저자의 연구 결과를 보여주고 있습니다. 3.1장을 읽어보면 자세히 알아볼 수 있습니다. 이는 네트워킹 스택에서의 과한 대기 때문이라고 하는데요. RPC 계층에서의 공격적 대기는 메모리 압력을 증가시키고 다른 작업과 메모리 간섭을 초래해 지연 시간을 더 길게 만든다고 합니다.  

그걸 개선하고자 많은 연구가 있었지만, 결국 CPU와 NIC 사이에 인터페이스에서 제한이 생긴다라는 것이죠. NIC은 프로세서에 PCIe로 연결된 주변장치일 뿐이고 PCIe에 의해 버스 트랜잭션이나 메모리 동기화 등에 제한이 생깁니다.
<br><br>
### Solutions

그래서 저자는 FPGA를 이용해 Reconfigurable한 RPC 스택을 만들었고, 이를 Dagger라고 칭했습니다.  
Dagger is based on three key design principles:  
1) NIC이 전체 RPC 스택을 하드웨어로 구현하고, 소프트웨어는 RPC API 제공만 담당하고  
2) Dagger가 프로세서와 통신하기 위해 메모리 인터커넥트를 활용하며  
3) FPGA 기반으로 완전히 프로그래밍이 가능하도록  

이렇게 함으로 Dagger를 통해 CPU 자원을 효율적으로 사용하고 요청 지연 시간을 크게 줄여보자는 것이죠!

<br><br>
## Summary
---


<br><br>

<br><br>
## Review
---


<br><br>
## Strength & Weakness
---


<br><br>

Thanks!!