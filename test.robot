*** Variables ***
${SCRIPT}                     ${CURDIR}/test.resc
${GPDMA1}                     0x40020000
# Channel x register offsets from the GPDMA1 base, 0xNN + x * 0x80 (DMA_Channel_TypeDef in
# stm32wba52xx.h): CCR 0x64, CTR1 0x90, CTR2 0x94, CBR1 0x98, CSAR 0x9C, CDAR 0xA0.
${C0TR1}                      0x90
${C0TR2}                      0x94
${C0BR1}                      0x98
${C0SAR}                      0x9C
${C0DAR}                      0xA0
${C0CR}                       0x64
${SOURCE}                     0x20001000
${DESTINATION}                0x20002000
# CxTR1: SDW_LOG2 = DDW_LOG2 = 2 (32-bit data), SINC, DINC.
${TR1_WORDS_INCREMENTED}      0x000A000A
# CxTR2: SWREQ (memory-to-memory).
${TR2_SOFTWARE_REQUEST}       0x00000200
${CR_ENABLE}                  0x00000001

*** Keywords ***
Load Script
    Execute Script            ${SCRIPT}

Write Word
    [Arguments]               ${address}    ${value}
    ${address}=               Evaluate      hex(${address})
    Execute Command           sysbus WriteDoubleWord ${address} ${value}

Word Should Be
    [Arguments]               ${address}    ${expected}
    ${address}=               Evaluate      hex(${address})
    ${value}=                 Execute Command    sysbus ReadDoubleWord ${address}
    Should Be Equal As Integers    ${value.strip()}    ${expected}
    ...                       msg=${address} reads ${value.strip()}, expected ${expected}    values=False

*** Test Cases ***
Should Copy Exactly BNDT Bytes With 32-Bit Data
    Load Script
    Write Word                ${SOURCE}                 0x11111111
    Write Word                ${SOURCE} + 4             0x22222222
    Write Word                ${SOURCE} + 8             0x33333333
    Write Word                ${DESTINATION} + 8        0xAAAAAAAA

    # Memory-to-memory block of 8 bytes (two 32-bit words) on channel 0.
    Write Word                ${GPDMA1} + ${C0TR1}      ${TR1_WORDS_INCREMENTED}
    Write Word                ${GPDMA1} + ${C0TR2}      ${TR2_SOFTWARE_REQUEST}
    Write Word                ${GPDMA1} + ${C0BR1}      8
    Write Word                ${GPDMA1} + ${C0SAR}      ${SOURCE}
    Write Word                ${GPDMA1} + ${C0DAR}      ${DESTINATION}
    Write Word                ${GPDMA1} + ${C0CR}       ${CR_ENABLE}

    Word Should Be            ${DESTINATION}            0x11111111
    Word Should Be            ${DESTINATION} + 4        0x22222222
    # The word after the 8-byte block must not be written.
    Word Should Be            ${DESTINATION} + 8        0xAAAAAAAA
