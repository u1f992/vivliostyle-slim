/**
 * from https://github.com/microsoft/playwright/blob/v1.60.0/packages/playwright-core/src/server/registry/nativeDeps.ts
 * 
 * LICENSE
 * ---
 *                                  Apache License
 *                            Version 2.0, January 2004
 *                         http://www.apache.org/licenses/
 * 
 *    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
 * 
 *    1. Definitions.
 * 
 *       "License" shall mean the terms and conditions for use, reproduction,
 *       and distribution as defined by Sections 1 through 9 of this document.
 * 
 *       "Licensor" shall mean the copyright owner or entity authorized by
 *       the copyright owner that is granting the License.
 * 
 *       "Legal Entity" shall mean the union of the acting entity and all
 *       other entities that control, are controlled by, or are under common
 *       control with that entity. For the purposes of this definition,
 *       "control" means (i) the power, direct or indirect, to cause the
 *       direction or management of such entity, whether by contract or
 *       otherwise, or (ii) ownership of fifty percent (50%) or more of the
 *       outstanding shares, or (iii) beneficial ownership of such entity.
 * 
 *       "You" (or "Your") shall mean an individual or Legal Entity
 *       exercising permissions granted by this License.
 * 
 *       "Source" form shall mean the preferred form for making modifications,
 *       including but not limited to software source code, documentation
 *       source, and configuration files.
 * 
 *       "Object" form shall mean any form resulting from mechanical
 *       transformation or translation of a Source form, including but
 *       not limited to compiled object code, generated documentation,
 *       and conversions to other media types.
 * 
 *       "Work" shall mean the work of authorship, whether in Source or
 *       Object form, made available under the License, as indicated by a
 *       copyright notice that is included in or attached to the work
 *       (an example is provided in the Appendix below).
 * 
 *       "Derivative Works" shall mean any work, whether in Source or Object
 *       form, that is based on (or derived from) the Work and for which the
 *       editorial revisions, annotations, elaborations, or other modifications
 *       represent, as a whole, an original work of authorship. For the purposes
 *       of this License, Derivative Works shall not include works that remain
 *       separable from, or merely link (or bind by name) to the interfaces of,
 *       the Work and Derivative Works thereof.
 * 
 *       "Contribution" shall mean any work of authorship, including
 *       the original version of the Work and any modifications or additions
 *       to that Work or Derivative Works thereof, that is intentionally
 *       submitted to Licensor for inclusion in the Work by the copyright owner
 *       or by an individual or Legal Entity authorized to submit on behalf of
 *       the copyright owner. For the purposes of this definition, "submitted"
 *       means any form of electronic, verbal, or written communication sent
 *       to the Licensor or its representatives, including but not limited to
 *       communication on electronic mailing lists, source code control systems,
 *       and issue tracking systems that are managed by, or on behalf of, the
 *       Licensor for the purpose of discussing and improving the Work, but
 *       excluding communication that is conspicuously marked or otherwise
 *       designated in writing by the copyright owner as "Not a Contribution."
 * 
 *       "Contributor" shall mean Licensor and any individual or Legal Entity
 *       on behalf of whom a Contribution has been received by Licensor and
 *       subsequently incorporated within the Work.
 * 
 *    2. Grant of Copyright License. Subject to the terms and conditions of
 *       this License, each Contributor hereby grants to You a perpetual,
 *       worldwide, non-exclusive, no-charge, royalty-free, irrevocable
 *       copyright license to reproduce, prepare Derivative Works of,
 *       publicly display, publicly perform, sublicense, and distribute the
 *       Work and such Derivative Works in Source or Object form.
 * 
 *    3. Grant of Patent License. Subject to the terms and conditions of
 *       this License, each Contributor hereby grants to You a perpetual,
 *       worldwide, non-exclusive, no-charge, royalty-free, irrevocable
 *       (except as stated in this section) patent license to make, have made,
 *       use, offer to sell, sell, import, and otherwise transfer the Work,
 *       where such license applies only to those patent claims licensable
 *       by such Contributor that are necessarily infringed by their
 *       Contribution(s) alone or by combination of their Contribution(s)
 *       with the Work to which such Contribution(s) was submitted. If You
 *       institute patent litigation against any entity (including a
 *       cross-claim or counterclaim in a lawsuit) alleging that the Work
 *       or a Contribution incorporated within the Work constitutes direct
 *       or contributory patent infringement, then any patent licenses
 *       granted to You under this License for that Work shall terminate
 *       as of the date such litigation is filed.
 * 
 *    4. Redistribution. You may reproduce and distribute copies of the
 *       Work or Derivative Works thereof in any medium, with or without
 *       modifications, and in Source or Object form, provided that You
 *       meet the following conditions:
 * 
 *       (a) You must give any other recipients of the Work or
 *           Derivative Works a copy of this License; and
 * 
 *       (b) You must cause any modified files to carry prominent notices
 *           stating that You changed the files; and
 * 
 *       (c) You must retain, in the Source form of any Derivative Works
 *           that You distribute, all copyright, patent, trademark, and
 *           attribution notices from the Source form of the Work,
 *           excluding those notices that do not pertain to any part of
 *           the Derivative Works; and
 * 
 *       (d) If the Work includes a "NOTICE" text file as part of its
 *           distribution, then any Derivative Works that You distribute must
 *           include a readable copy of the attribution notices contained
 *           within such NOTICE file, excluding those notices that do not
 *           pertain to any part of the Derivative Works, in at least one
 *           of the following places: within a NOTICE text file distributed
 *           as part of the Derivative Works; within the Source form or
 *           documentation, if provided along with the Derivative Works; or,
 *           within a display generated by the Derivative Works, if and
 *           wherever such third-party notices normally appear. The contents
 *           of the NOTICE file are for informational purposes only and
 *           do not modify the License. You may add Your own attribution
 *           notices within Derivative Works that You distribute, alongside
 *           or as an addendum to the NOTICE text from the Work, provided
 *           that such additional attribution notices cannot be construed
 *           as modifying the License.
 * 
 *       You may add Your own copyright statement to Your modifications and
 *       may provide additional or different license terms and conditions
 *       for use, reproduction, or distribution of Your modifications, or
 *       for any such Derivative Works as a whole, provided Your use,
 *       reproduction, and distribution of the Work otherwise complies with
 *       the conditions stated in this License.
 * 
 *    5. Submission of Contributions. Unless You explicitly state otherwise,
 *       any Contribution intentionally submitted for inclusion in the Work
 *       by You to the Licensor shall be under the terms and conditions of
 *       this License, without any additional terms or conditions.
 *       Notwithstanding the above, nothing herein shall supersede or modify
 *       the terms of any separate license agreement you may have executed
 *       with Licensor regarding such Contributions.
 * 
 *    6. Trademarks. This License does not grant permission to use the trade
 *       names, trademarks, service marks, or product names of the Licensor,
 *       except as required for reasonable and customary use in describing the
 *       origin of the Work and reproducing the content of the NOTICE file.
 * 
 *    7. Disclaimer of Warranty. Unless required by applicable law or
 *       agreed to in writing, Licensor provides the Work (and each
 *       Contributor provides its Contributions) on an "AS IS" BASIS,
 *       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *       implied, including, without limitation, any warranties or conditions
 *       of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
 *       PARTICULAR PURPOSE. You are solely responsible for determining the
 *       appropriateness of using or redistributing the Work and assume any
 *       risks associated with Your exercise of permissions under this License.
 * 
 *    8. Limitation of Liability. In no event and under no legal theory,
 *       whether in tort (including negligence), contract, or otherwise,
 *       unless required by applicable law (such as deliberate and grossly
 *       negligent acts) or agreed to in writing, shall any Contributor be
 *       liable to You for damages, including any direct, indirect, special,
 *       incidental, or consequential damages of any character arising as a
 *       result of this License or out of the use or inability to use the
 *       Work (including but not limited to damages for loss of goodwill,
 *       work stoppage, computer failure or malfunction, or any and all
 *       other commercial damages or losses), even if such Contributor
 *       has been advised of the possibility of such damages.
 * 
 *    9. Accepting Warranty or Additional Liability. While redistributing
 *       the Work or Derivative Works thereof, You may choose to offer,
 *       and charge a fee for, acceptance of support, warranty, indemnity,
 *       or other liability obligations and/or rights consistent with this
 *       License. However, in accepting such obligations, You may act only
 *       on Your own behalf and on Your sole responsibility, not on behalf
 *       of any other Contributor, and only if You agree to indemnify,
 *       defend, and hold each Contributor harmless for any liability
 *       incurred by, or claims asserted against, such Contributor by reason
 *       of your accepting any such warranty or additional liability.
 * 
 *    END OF TERMS AND CONDITIONS
 * 
 *    APPENDIX: How to apply the Apache License to your work.
 * 
 *       To apply the Apache License to your work, attach the following
 *       boilerplate notice, with the fields enclosed by brackets "[]"
 *       replaced with your own identifying information. (Don't include
 *       the brackets!)  The text should be enclosed in the appropriate
 *       comment syntax for the file format. We also recommend that a
 *       file or class name and description of purpose be included on the
 *       same "printed page" as the copyright notice for easier
 *       identification within third-party archives.
 * 
 *    Portions Copyright (c) Microsoft Corporation.
 *    Portions Copyright 2017 Google Inc.
 * 
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 * 
 *        http://www.apache.org/licenses/LICENSE-2.0
 * 
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 * 
 * NOTICE
 * ---
 * Playwright
 * Copyright (c) Microsoft Corporation
 * 
 * This software contains code derived from the Puppeteer project (https://github.com/puppeteer/puppeteer),
 * available under the Apache 2.0 license (https://github.com/puppeteer/puppeteer/blob/master/LICENSE).
 */

/**
 * Copyright (c) Microsoft Corporation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// - This file is used to execute 'npx playwright install-deps'
// - The reverse mappings "lib2package" are generated with the following script:
//     ./utils/linux-browser-dependencies/run.sh ubuntu:20.04

export const deps: any = {
  'ubuntu20.04-x64': {
    tools: [
      'xvfb',
      'fonts-noto-color-emoji',
      'ttf-unifont',
      'libfontconfig',
      'libfreetype6',
      'xfonts-cyrillic',
      'xfonts-scalable',
      'fonts-liberation',
      'fonts-ipafont-gothic',
      'fonts-wqy-zenhei',
      'fonts-tlwg-loma-otf',
      'ttf-ubuntu-font-family',
    ],
    chromium: [
      'fonts-liberation',
      'libasound2',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libatspi2.0-0',
      'libcairo2',
      'libcups2',
      'libdbus-1-3',
      'libdrm2',
      'libegl1',
      'libgbm1',
      'libglib2.0-0',
      'libgtk-3-0',
      'libnspr4',
      'libnss3',
      'libpango-1.0-0',
      'libx11-6',
      'libx11-xcb1',
      'libxcb1',
      'libxcomposite1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxrandr2',
      'libxshmfence1',
    ],
    firefox: [
      'ffmpeg',
      'libatk1.0-0',
      'libcairo-gobject2',
      'libcairo2',
      'libdbus-1-3',
      'libdbus-glib-1-2',
      'libfontconfig1',
      'libfreetype6',
      'libgdk-pixbuf2.0-0',
      'libglib2.0-0',
      'libgtk-3-0',
      'libpango-1.0-0',
      'libpangocairo-1.0-0',
      'libpangoft2-1.0-0',
      'libx11-6',
      'libx11-xcb1',
      'libxcb-shm0',
      'libxcb1',
      'libxcomposite1',
      'libxcursor1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxi6',
      'libxrender1',
      'libxt6',
      'libxtst6'
    ],
    webkit: [
      'libenchant-2-2',
      'libflite1',
      'libx264-155',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libcairo2',
      'libegl1',
      'libenchant1c2a',
      'libepoxy0',
      'libevdev2',
      'libfontconfig1',
      'libfreetype6',
      'libgdk-pixbuf2.0-0',
      'libgl1',
      'libgles2',
      'libglib2.0-0',
      'libgtk-3-0',
      'libgudev-1.0-0',
      'libharfbuzz-icu0',
      'libharfbuzz0b',
      'libhyphen0',
      'libicu66',
      'libjpeg-turbo8',
      'libnghttp2-14',
      'libnotify4',
      'libopengl0',
      'libopenjp2-7',
      'libopus0',
      'libpango-1.0-0',
      'libpng16-16',
      'libsecret-1-0',
      'libvpx6',
      'libwayland-client0',
      'libwayland-egl1',
      'libwayland-server0',
      'libwebp6',
      'libwebpdemux2',
      'libwoff1',
      'libx11-6',
      'libxcomposite1',
      'libxdamage1',
      'libxkbcommon0',
      'libxml2',
      'libxslt1.1',
      'libatomic1',
      'libevent-2.1-7',
    ],
    lib2package: {
      'libflite.so.1': 'libflite1',
      'libflite_usenglish.so.1': 'libflite1',
      'libflite_cmu_grapheme_lang.so.1': 'libflite1',
      'libflite_cmu_grapheme_lex.so.1': 'libflite1',
      'libflite_cmu_indic_lang.so.1': 'libflite1',
      'libflite_cmu_indic_lex.so.1': 'libflite1',
      'libflite_cmulex.so.1': 'libflite1',
      'libflite_cmu_time_awb.so.1': 'libflite1',
      'libflite_cmu_us_awb.so.1': 'libflite1',
      'libflite_cmu_us_kal16.so.1': 'libflite1',
      'libflite_cmu_us_kal.so.1': 'libflite1',
      'libflite_cmu_us_rms.so.1': 'libflite1',
      'libflite_cmu_us_slt.so.1': 'libflite1',
      'libx264.so': 'libx264-155',
      'libasound.so.2': 'libasound2',
      'libatk-1.0.so.0': 'libatk1.0-0',
      'libatk-bridge-2.0.so.0': 'libatk-bridge2.0-0',
      'libatspi.so.0': 'libatspi2.0-0',
      'libcairo-gobject.so.2': 'libcairo-gobject2',
      'libcairo.so.2': 'libcairo2',
      'libcups.so.2': 'libcups2',
      'libdbus-1.so.3': 'libdbus-1-3',
      'libdbus-glib-1.so.2': 'libdbus-glib-1-2',
      'libdrm.so.2': 'libdrm2',
      'libEGL.so.1': 'libegl1',
      'libenchant.so.1': 'libenchant1c2a',
      'libevdev.so.2': 'libevdev2',
      'libepoxy.so.0': 'libepoxy0',
      'libfontconfig.so.1': 'libfontconfig1',
      'libfreetype.so.6': 'libfreetype6',
      'libgbm.so.1': 'libgbm1',
      'libgdk_pixbuf-2.0.so.0': 'libgdk-pixbuf2.0-0',
      'libgdk-3.so.0': 'libgtk-3-0',
      'libgdk-x11-2.0.so.0': 'libgtk2.0-0',
      'libgio-2.0.so.0': 'libglib2.0-0',
      'libGL.so.1': 'libgl1',
      'libGLESv2.so.2': 'libgles2',
      'libglib-2.0.so.0': 'libglib2.0-0',
      'libgmodule-2.0.so.0': 'libglib2.0-0',
      'libgobject-2.0.so.0': 'libglib2.0-0',
      'libgthread-2.0.so.0': 'libglib2.0-0',
      'libgtk-3.so.0': 'libgtk-3-0',
      'libgtk-x11-2.0.so.0': 'libgtk2.0-0',
      'libgudev-1.0.so.0': 'libgudev-1.0-0',
      'libharfbuzz-icu.so.0': 'libharfbuzz-icu0',
      'libharfbuzz.so.0': 'libharfbuzz0b',
      'libhyphen.so.0': 'libhyphen0',
      'libicui18n.so.66': 'libicu66',
      'libicuuc.so.66': 'libicu66',
      'libjpeg.so.8': 'libjpeg-turbo8',
      'libnotify.so.4': 'libnotify4',
      'libnspr4.so': 'libnspr4',
      'libnss3.so': 'libnss3',
      'libnssutil3.so': 'libnss3',
      'libOpenGL.so.0': 'libopengl0',
      'libopenjp2.so.7': 'libopenjp2-7',
      'libopus.so.0': 'libopus0',
      'libpango-1.0.so.0': 'libpango-1.0-0',
      'libpangocairo-1.0.so.0': 'libpangocairo-1.0-0',
      'libpangoft2-1.0.so.0': 'libpangoft2-1.0-0',
      'libpng16.so.16': 'libpng16-16',
      'libsecret-1.so.0': 'libsecret-1-0',
      'libsmime3.so': 'libnss3',
      'libvpx.so.6': 'libvpx6',
      'libwayland-client.so.0': 'libwayland-client0',
      'libwayland-egl.so.1': 'libwayland-egl1',
      'libwayland-server.so.0': 'libwayland-server0',
      'libwebp.so.6': 'libwebp6',
      'libwebpdemux.so.2': 'libwebpdemux2',
      'libwoff2dec.so.1.0.2': 'libwoff1',
      'libX11-xcb.so.1': 'libx11-xcb1',
      'libX11.so.6': 'libx11-6',
      'libxcb-dri3.so.0': 'libxcb-dri3-0',
      'libxcb-shm.so.0': 'libxcb-shm0',
      'libxcb.so.1': 'libxcb1',
      'libXcomposite.so.1': 'libxcomposite1',
      'libXcursor.so.1': 'libxcursor1',
      'libXdamage.so.1': 'libxdamage1',
      'libXext.so.6': 'libxext6',
      'libXfixes.so.3': 'libxfixes3',
      'libXi.so.6': 'libxi6',
      'libxkbcommon.so.0': 'libxkbcommon0',
      'libxml2.so.2': 'libxml2',
      'libXrandr.so.2': 'libxrandr2',
      'libXrender.so.1': 'libxrender1',
      'libxslt.so.1': 'libxslt1.1',
      'libXt.so.6': 'libxt6',
      'libXtst.so.6': 'libxtst6',
      'libxshmfence.so.1': 'libxshmfence1',
      'libatomic.so.1': 'libatomic1',
      'libenchant-2.so.2': 'libenchant-2-2',
      'libevent-2.1.so.7': 'libevent-2.1-7',
    },
  },

  'ubuntu22.04-x64': {
    tools: [
      'xvfb',
      'fonts-noto-color-emoji',
      'fonts-unifont',
      'libfontconfig1',
      'libfreetype6',
      'xfonts-cyrillic',
      'xfonts-scalable',
      'fonts-liberation',
      'fonts-ipafont-gothic',
      'fonts-wqy-zenhei',
      'fonts-tlwg-loma-otf',
      'fonts-freefont-ttf',
    ],
    chromium: [
      'libasound2',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libatspi2.0-0',
      'libcairo2',
      'libcups2',
      'libdbus-1-3',
      'libdrm2',
      'libgbm1',
      'libglib2.0-0',
      'libnspr4',
      'libnss3',
      'libpango-1.0-0',
      'libwayland-client0',
      'libx11-6',
      'libxcb1',
      'libxcomposite1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxkbcommon0',
      'libxrandr2'
    ],
    firefox: [
      'ffmpeg',
      'libasound2',
      'libatk1.0-0',
      'libcairo-gobject2',
      'libcairo2',
      'libdbus-1-3',
      'libdbus-glib-1-2',
      'libfontconfig1',
      'libfreetype6',
      'libgdk-pixbuf-2.0-0',
      'libglib2.0-0',
      'libgtk-3-0',
      'libpango-1.0-0',
      'libpangocairo-1.0-0',
      'libx11-6',
      'libx11-xcb1',
      'libxcb-shm0',
      'libxcb1',
      'libxcomposite1',
      'libxcursor1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxi6',
      'libxrandr2',
      'libxrender1',
      'libxtst6'
    ],
    webkit: [
      'libsoup-3.0-0',
      'libenchant-2-2',
      'gstreamer1.0-libav',
      'gstreamer1.0-plugins-bad',
      'gstreamer1.0-plugins-base',
      'gstreamer1.0-plugins-good',
      'libicu70',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libcairo2',
      'libdbus-1-3',
      'libdrm2',
      'libegl1',
      'libepoxy0',
      'libevdev2',
      'libffi7',
      'libfontconfig1',
      'libfreetype6',
      'libgbm1',
      'libgdk-pixbuf-2.0-0',
      'libgles2',
      'libglib2.0-0',
      'libglx0',
      'libgstreamer-gl1.0-0',
      'libgstreamer-plugins-base1.0-0',
      'libgstreamer1.0-0',
      'libgtk-4-1',
      'libgudev-1.0-0',
      'libharfbuzz-icu0',
      'libharfbuzz0b',
      'libhyphen0',
      'libjpeg-turbo8',
      'liblcms2-2',
      'libmanette-0.2-0',
      'libnotify4',
      'libopengl0',
      'libopenjp2-7',
      'libopus0',
      'libpango-1.0-0',
      'libpng16-16',
      'libproxy1v5',
      'libsecret-1-0',
      'libwayland-client0',
      'libwayland-egl1',
      'libwayland-server0',
      'libwebpdemux2',
      'libwoff1',
      'libx11-6',
      'libxcomposite1',
      'libxdamage1',
      'libxkbcommon0',
      'libxml2',
      'libxslt1.1',
      'libx264-163',
      'libatomic1',
      'libevent-2.1-7',
      'libavif13',
    ],
    lib2package: {
      'libavif.so.13': 'libavif13',
      'libsoup-3.0.so.0': 'libsoup-3.0-0',
      'libasound.so.2': 'libasound2',
      'libatk-1.0.so.0': 'libatk1.0-0',
      'libatk-bridge-2.0.so.0': 'libatk-bridge2.0-0',
      'libatspi.so.0': 'libatspi2.0-0',
      'libcairo-gobject.so.2': 'libcairo-gobject2',
      'libcairo.so.2': 'libcairo2',
      'libcups.so.2': 'libcups2',
      'libdbus-1.so.3': 'libdbus-1-3',
      'libdbus-glib-1.so.2': 'libdbus-glib-1-2',
      'libdrm.so.2': 'libdrm2',
      'libEGL.so.1': 'libegl1',
      'libepoxy.so.0': 'libepoxy0',
      'libevdev.so.2': 'libevdev2',
      'libffi.so.7': 'libffi7',
      'libfontconfig.so.1': 'libfontconfig1',
      'libfreetype.so.6': 'libfreetype6',
      'libgbm.so.1': 'libgbm1',
      'libgdk_pixbuf-2.0.so.0': 'libgdk-pixbuf-2.0-0',
      'libgdk-3.so.0': 'libgtk-3-0',
      'libgio-2.0.so.0': 'libglib2.0-0',
      'libGLESv2.so.2': 'libgles2',
      'libglib-2.0.so.0': 'libglib2.0-0',
      'libGLX.so.0': 'libglx0',
      'libgmodule-2.0.so.0': 'libglib2.0-0',
      'libgobject-2.0.so.0': 'libglib2.0-0',
      'libgstallocators-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstapp-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstaudio-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstbase-1.0.so.0': 'libgstreamer1.0-0',
      'libgstfft-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstgl-1.0.so.0': 'libgstreamer-gl1.0-0',
      'libgstpbutils-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstreamer-1.0.so.0': 'libgstreamer1.0-0',
      'libgsttag-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstvideo-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgtk-3.so.0': 'libgtk-3-0',
      'libgtk-4.so.1': 'libgtk-4-1',
      'libgudev-1.0.so.0': 'libgudev-1.0-0',
      'libharfbuzz-icu.so.0': 'libharfbuzz-icu0',
      'libharfbuzz.so.0': 'libharfbuzz0b',
      'libhyphen.so.0': 'libhyphen0',
      'libjpeg.so.8': 'libjpeg-turbo8',
      'liblcms2.so.2': 'liblcms2-2',
      'libmanette-0.2.so.0': 'libmanette-0.2-0',
      'libnotify.so.4': 'libnotify4',
      'libnspr4.so': 'libnspr4',
      'libnss3.so': 'libnss3',
      'libnssutil3.so': 'libnss3',
      'libOpenGL.so.0': 'libopengl0',
      'libopenjp2.so.7': 'libopenjp2-7',
      'libopus.so.0': 'libopus0',
      'libpango-1.0.so.0': 'libpango-1.0-0',
      'libpangocairo-1.0.so.0': 'libpangocairo-1.0-0',
      'libpng16.so.16': 'libpng16-16',
      'libproxy.so.1': 'libproxy1v5',
      'libsecret-1.so.0': 'libsecret-1-0',
      'libsmime3.so': 'libnss3',
      'libwayland-client.so.0': 'libwayland-client0',
      'libwayland-egl.so.1': 'libwayland-egl1',
      'libwayland-server.so.0': 'libwayland-server0',
      'libwebpdemux.so.2': 'libwebpdemux2',
      'libwoff2dec.so.1.0.2': 'libwoff1',
      'libX11-xcb.so.1': 'libx11-xcb1',
      'libX11.so.6': 'libx11-6',
      'libxcb-shm.so.0': 'libxcb-shm0',
      'libxcb.so.1': 'libxcb1',
      'libXcomposite.so.1': 'libxcomposite1',
      'libXcursor.so.1': 'libxcursor1',
      'libXdamage.so.1': 'libxdamage1',
      'libXext.so.6': 'libxext6',
      'libXfixes.so.3': 'libxfixes3',
      'libXi.so.6': 'libxi6',
      'libxkbcommon.so.0': 'libxkbcommon0',
      'libxml2.so.2': 'libxml2',
      'libXrandr.so.2': 'libxrandr2',
      'libXrender.so.1': 'libxrender1',
      'libxslt.so.1': 'libxslt1.1',
      'libXtst.so.6': 'libxtst6',
      'libicui18n.so.60': 'libicu70',
      'libicuuc.so.66': 'libicu70',
      'libicui18n.so.66': 'libicu70',
      'libwebp.so.6': 'libwebp6',
      'libenchant-2.so.2': 'libenchant-2-2',
      'libx264.so': 'libx264-163',
      'libvpx.so.7': 'libvpx7',
      'libatomic.so.1': 'libatomic1',
      'libevent-2.1.so.7': 'libevent-2.1-7',
    },
  },

  'ubuntu24.04-x64': {
    tools: [
      'xvfb',
      'fonts-noto-color-emoji',
      'fonts-unifont',
      'libfontconfig1',
      'libfreetype6',
      'xfonts-cyrillic',
      'xfonts-scalable',
      'fonts-liberation',
      'fonts-ipafont-gothic',
      'fonts-wqy-zenhei',
      'fonts-tlwg-loma-otf',
      'fonts-freefont-ttf',
    ],
    chromium: [
      'libasound2t64',
      'libatk-bridge2.0-0t64',
      'libatk1.0-0t64',
      'libatspi2.0-0t64',
      'libcairo2',
      'libcups2t64',
      'libdbus-1-3',
      'libdrm2',
      'libgbm1',
      'libglib2.0-0t64',
      'libnspr4',
      'libnss3',
      'libpango-1.0-0',
      'libx11-6',
      'libxcb1',
      'libxcomposite1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxkbcommon0',
      'libxrandr2'
    ],
    firefox: [
      'libasound2t64',
      'libatk1.0-0t64',
      'libavcodec60',
      'libcairo-gobject2',
      'libcairo2',
      'libdbus-1-3',
      'libfontconfig1',
      'libfreetype6',
      'libgdk-pixbuf-2.0-0',
      'libglib2.0-0t64',
      'libgtk-3-0t64',
      'libpango-1.0-0',
      'libpangocairo-1.0-0',
      'libx11-6',
      'libx11-xcb1',
      'libxcb-shm0',
      'libxcb1',
      'libxcomposite1',
      'libxcursor1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxi6',
      'libxrandr2',
      'libxrender1'
    ],
    webkit: [
      'gstreamer1.0-libav',
      'gstreamer1.0-plugins-bad',
      'gstreamer1.0-plugins-base',
      'gstreamer1.0-plugins-good',
      'libicu74',
      'libatomic1',
      'libatk-bridge2.0-0t64',
      'libatk1.0-0t64',
      'libcairo-gobject2',
      'libcairo2',
      'libdbus-1-3',
      'libdrm2',
      'libenchant-2-2',
      'libepoxy0',
      'libevent-2.1-7t64',
      'libflite1',
      'libfontconfig1',
      'libfreetype6',
      'libgbm1',
      'libgdk-pixbuf-2.0-0',
      'libgles2',
      'libglib2.0-0t64',
      'libgstreamer-gl1.0-0',
      'libgstreamer-plugins-bad1.0-0',
      'libgstreamer-plugins-base1.0-0',
      'libgstreamer1.0-0',
      'libgtk-4-1',
      'libharfbuzz-icu0',
      'libharfbuzz0b',
      'libhyphen0',
      'libicu74',
      'libjpeg-turbo8',
      'liblcms2-2',
      'libmanette-0.2-0',
      'libopus0',
      'libpango-1.0-0',
      'libpangocairo-1.0-0',
      'libpng16-16t64',
      'libsecret-1-0',
      'libvpx9',
      'libwayland-client0',
      'libwayland-egl1',
      'libwayland-server0',
      'libwebp7',
      'libwebpdemux2',
      'libwoff1',
      'libx11-6',
      'libxkbcommon0',
      'libxml2',
      'libxslt1.1',
      'libx264-164',
      'libavif16',
    ],
    lib2package: {
      'libavif.so.16': 'libavif16',
      'libasound.so.2': 'libasound2t64',
      'libatk-1.0.so.0': 'libatk1.0-0t64',
      'libatk-bridge-2.0.so.0': 'libatk-bridge2.0-0t64',
      'libatomic.so.1': 'libatomic1',
      'libatspi.so.0': 'libatspi2.0-0t64',
      'libcairo-gobject.so.2': 'libcairo-gobject2',
      'libcairo.so.2': 'libcairo2',
      'libcups.so.2': 'libcups2t64',
      'libdbus-1.so.3': 'libdbus-1-3',
      'libdrm.so.2': 'libdrm2',
      'libenchant-2.so.2': 'libenchant-2-2',
      'libepoxy.so.0': 'libepoxy0',
      'libevent-2.1.so.7': 'libevent-2.1-7t64',
      'libflite_cmu_grapheme_lang.so.1': 'libflite1',
      'libflite_cmu_grapheme_lex.so.1': 'libflite1',
      'libflite_cmu_indic_lang.so.1': 'libflite1',
      'libflite_cmu_indic_lex.so.1': 'libflite1',
      'libflite_cmu_time_awb.so.1': 'libflite1',
      'libflite_cmu_us_awb.so.1': 'libflite1',
      'libflite_cmu_us_kal.so.1': 'libflite1',
      'libflite_cmu_us_kal16.so.1': 'libflite1',
      'libflite_cmu_us_rms.so.1': 'libflite1',
      'libflite_cmu_us_slt.so.1': 'libflite1',
      'libflite_cmulex.so.1': 'libflite1',
      'libflite_usenglish.so.1': 'libflite1',
      'libflite.so.1': 'libflite1',
      'libfontconfig.so.1': 'libfontconfig1',
      'libfreetype.so.6': 'libfreetype6',
      'libgbm.so.1': 'libgbm1',
      'libgdk_pixbuf-2.0.so.0': 'libgdk-pixbuf-2.0-0',
      'libgdk-3.so.0': 'libgtk-3-0t64',
      'libgio-2.0.so.0': 'libglib2.0-0t64',
      'libGLESv2.so.2': 'libgles2',
      'libglib-2.0.so.0': 'libglib2.0-0t64',
      'libgmodule-2.0.so.0': 'libglib2.0-0t64',
      'libgobject-2.0.so.0': 'libglib2.0-0t64',
      'libgstallocators-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstapp-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstaudio-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstbase-1.0.so.0': 'libgstreamer1.0-0',
      'libgstcodecparsers-1.0.so.0': 'libgstreamer-plugins-bad1.0-0',
      'libgstfft-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstgl-1.0.so.0': 'libgstreamer-gl1.0-0',
      'libgstpbutils-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstreamer-1.0.so.0': 'libgstreamer1.0-0',
      'libgsttag-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstvideo-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgtk-3.so.0': 'libgtk-3-0t64',
      'libgtk-4.so.1': 'libgtk-4-1',
      'libharfbuzz-icu.so.0': 'libharfbuzz-icu0',
      'libharfbuzz.so.0': 'libharfbuzz0b',
      'libhyphen.so.0': 'libhyphen0',
      'libicudata.so.74': 'libicu74',
      'libicui18n.so.74': 'libicu74',
      'libicuuc.so.74': 'libicu74',
      'libjpeg.so.8': 'libjpeg-turbo8',
      'liblcms2.so.2': 'liblcms2-2',
      'libmanette-0.2.so.0': 'libmanette-0.2-0',
      'libnspr4.so': 'libnspr4',
      'libnss3.so': 'libnss3',
      'libnssutil3.so': 'libnss3',
      'libopus.so.0': 'libopus0',
      'libpango-1.0.so.0': 'libpango-1.0-0',
      'libpangocairo-1.0.so.0': 'libpangocairo-1.0-0',
      'libpng16.so.16': 'libpng16-16t64',
      'libsecret-1.so.0': 'libsecret-1-0',
      'libsmime3.so': 'libnss3',
      'libsoup-3.0.so.0': 'libsoup-3.0-0',
      'libvpx.so.9': 'libvpx9',
      'libwayland-client.so.0': 'libwayland-client0',
      'libwayland-egl.so.1': 'libwayland-egl1',
      'libwayland-server.so.0': 'libwayland-server0',
      'libwebp.so.7': 'libwebp7',
      'libwebpdemux.so.2': 'libwebpdemux2',
      'libwoff2dec.so.1.0.2': 'libwoff1',
      'libX11-xcb.so.1': 'libx11-xcb1',
      'libX11.so.6': 'libx11-6',
      'libxcb-shm.so.0': 'libxcb-shm0',
      'libxcb.so.1': 'libxcb1',
      'libXcomposite.so.1': 'libxcomposite1',
      'libXcursor.so.1': 'libxcursor1',
      'libXdamage.so.1': 'libxdamage1',
      'libXext.so.6': 'libxext6',
      'libXfixes.so.3': 'libxfixes3',
      'libXi.so.6': 'libxi6',
      'libxkbcommon.so.0': 'libxkbcommon0',
      'libxml2.so.2': 'libxml2',
      'libXrandr.so.2': 'libxrandr2',
      'libXrender.so.1': 'libxrender1',
      'libxslt.so.1': 'libxslt1.1',
      'libx264.so': 'libx264-164',
    },
  },

  'debian11-x64': {
    tools: [
      'xvfb',
      'fonts-noto-color-emoji',
      'fonts-unifont',
      'libfontconfig1',
      'libfreetype6',
      'xfonts-cyrillic',
      'xfonts-scalable',
      'fonts-liberation',
      'fonts-ipafont-gothic',
      'fonts-wqy-zenhei',
      'fonts-tlwg-loma-otf',
      'fonts-freefont-ttf',
    ],
    chromium: [
      'libasound2',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libatspi2.0-0',
      'libcairo2',
      'libcups2',
      'libdbus-1-3',
      'libdrm2',
      'libgbm1',
      'libglib2.0-0',
      'libnspr4',
      'libnss3',
      'libpango-1.0-0',
      'libwayland-client0',
      'libx11-6',
      'libxcb1',
      'libxcomposite1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxkbcommon0',
      'libxrandr2'
    ],
    firefox: [
      'libasound2',
      'libatk1.0-0',
      'libcairo-gobject2',
      'libcairo2',
      'libdbus-1-3',
      'libdbus-glib-1-2',
      'libfontconfig1',
      'libfreetype6',
      'libgdk-pixbuf-2.0-0',
      'libglib2.0-0',
      'libgtk-3-0',
      'libharfbuzz0b',
      'libpango-1.0-0',
      'libpangocairo-1.0-0',
      'libx11-6',
      'libx11-xcb1',
      'libxcb-shm0',
      'libxcb1',
      'libxcomposite1',
      'libxcursor1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxi6',
      'libxrandr2',
      'libxrender1',
      'libxtst6'
    ],
    webkit: [
      'gstreamer1.0-libav',
      'gstreamer1.0-plugins-bad',
      'gstreamer1.0-plugins-base',
      'gstreamer1.0-plugins-good',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libcairo2',
      'libdbus-1-3',
      'libdrm2',
      'libegl1',
      'libenchant-2-2',
      'libepoxy0',
      'libevdev2',
      'libfontconfig1',
      'libfreetype6',
      'libgbm1',
      'libgdk-pixbuf-2.0-0',
      'libgles2',
      'libglib2.0-0',
      'libglx0',
      'libgstreamer-gl1.0-0',
      'libgstreamer-plugins-base1.0-0',
      'libgstreamer1.0-0',
      'libgtk-3-0',
      'libgudev-1.0-0',
      'libharfbuzz-icu0',
      'libharfbuzz0b',
      'libhyphen0',
      'libicu67',
      'libjpeg62-turbo',
      'liblcms2-2',
      'libmanette-0.2-0',
      'libnghttp2-14',
      'libnotify4',
      'libopengl0',
      'libopenjp2-7',
      'libopus0',
      'libpango-1.0-0',
      'libpng16-16',
      'libproxy1v5',
      'libsecret-1-0',
      'libwayland-client0',
      'libwayland-egl1',
      'libwayland-server0',
      'libwebp6',
      'libwebpdemux2',
      'libwoff1',
      'libx11-6',
      'libxcomposite1',
      'libxdamage1',
      'libxkbcommon0',
      'libxml2',
      'libxslt1.1',
      'libatomic1',
      'libevent-2.1-7',
    ],
    lib2package: {
      'libasound.so.2': 'libasound2',
      'libatk-1.0.so.0': 'libatk1.0-0',
      'libatk-bridge-2.0.so.0': 'libatk-bridge2.0-0',
      'libatspi.so.0': 'libatspi2.0-0',
      'libcairo-gobject.so.2': 'libcairo-gobject2',
      'libcairo.so.2': 'libcairo2',
      'libcups.so.2': 'libcups2',
      'libdbus-1.so.3': 'libdbus-1-3',
      'libdbus-glib-1.so.2': 'libdbus-glib-1-2',
      'libdrm.so.2': 'libdrm2',
      'libEGL.so.1': 'libegl1',
      'libenchant-2.so.2': 'libenchant-2-2',
      'libepoxy.so.0': 'libepoxy0',
      'libevdev.so.2': 'libevdev2',
      'libfontconfig.so.1': 'libfontconfig1',
      'libfreetype.so.6': 'libfreetype6',
      'libgbm.so.1': 'libgbm1',
      'libgdk_pixbuf-2.0.so.0': 'libgdk-pixbuf-2.0-0',
      'libgdk-3.so.0': 'libgtk-3-0',
      'libgio-2.0.so.0': 'libglib2.0-0',
      'libGLESv2.so.2': 'libgles2',
      'libglib-2.0.so.0': 'libglib2.0-0',
      'libGLX.so.0': 'libglx0',
      'libgmodule-2.0.so.0': 'libglib2.0-0',
      'libgobject-2.0.so.0': 'libglib2.0-0',
      'libgstallocators-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstapp-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstaudio-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstbase-1.0.so.0': 'libgstreamer1.0-0',
      'libgstfft-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstgl-1.0.so.0': 'libgstreamer-gl1.0-0',
      'libgstpbutils-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstreamer-1.0.so.0': 'libgstreamer1.0-0',
      'libgsttag-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgstvideo-1.0.so.0': 'libgstreamer-plugins-base1.0-0',
      'libgtk-3.so.0': 'libgtk-3-0',
      'libgudev-1.0.so.0': 'libgudev-1.0-0',
      'libharfbuzz-icu.so.0': 'libharfbuzz-icu0',
      'libharfbuzz.so.0': 'libharfbuzz0b',
      'libhyphen.so.0': 'libhyphen0',
      'libicui18n.so.67': 'libicu67',
      'libicuuc.so.67': 'libicu67',
      'libjpeg.so.62': 'libjpeg62-turbo',
      'liblcms2.so.2': 'liblcms2-2',
      'libmanette-0.2.so.0': 'libmanette-0.2-0',
      'libnotify.so.4': 'libnotify4',
      'libnspr4.so': 'libnspr4',
      'libnss3.so': 'libnss3',
      'libnssutil3.so': 'libnss3',
      'libOpenGL.so.0': 'libopengl0',
      'libopenjp2.so.7': 'libopenjp2-7',
      'libopus.so.0': 'libopus0',
      'libpango-1.0.so.0': 'libpango-1.0-0',
      'libpangocairo-1.0.so.0': 'libpangocairo-1.0-0',
      'libpng16.so.16': 'libpng16-16',
      'libproxy.so.1': 'libproxy1v5',
      'libsecret-1.so.0': 'libsecret-1-0',
      'libsmime3.so': 'libnss3',
      'libwayland-client.so.0': 'libwayland-client0',
      'libwayland-egl.so.1': 'libwayland-egl1',
      'libwayland-server.so.0': 'libwayland-server0',
      'libwebp.so.6': 'libwebp6',
      'libwebpdemux.so.2': 'libwebpdemux2',
      'libwoff2dec.so.1.0.2': 'libwoff1',
      'libX11-xcb.so.1': 'libx11-xcb1',
      'libX11.so.6': 'libx11-6',
      'libxcb-shm.so.0': 'libxcb-shm0',
      'libxcb.so.1': 'libxcb1',
      'libXcomposite.so.1': 'libxcomposite1',
      'libXcursor.so.1': 'libxcursor1',
      'libXdamage.so.1': 'libxdamage1',
      'libXext.so.6': 'libxext6',
      'libXfixes.so.3': 'libxfixes3',
      'libXi.so.6': 'libxi6',
      'libxkbcommon.so.0': 'libxkbcommon0',
      'libxml2.so.2': 'libxml2',
      'libXrandr.so.2': 'libxrandr2',
      'libXrender.so.1': 'libxrender1',
      'libxslt.so.1': 'libxslt1.1',
      'libXtst.so.6': 'libxtst6',
      'libatomic.so.1': 'libatomic1',
      'libevent-2.1.so.7': 'libevent-2.1-7',
    }
  },
  'debian12-x64': {
    tools: [
      'xvfb',
      'fonts-noto-color-emoji',
      'fonts-unifont',
      'libfontconfig1',
      'libfreetype6',
      'xfonts-scalable',
      'fonts-liberation',
      'fonts-ipafont-gothic',
      'fonts-wqy-zenhei',
      'fonts-tlwg-loma-otf',
      'fonts-freefont-ttf',
    ],
    chromium: [
      'libasound2',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libatspi2.0-0',
      'libcairo2',
      'libcups2',
      'libdbus-1-3',
      'libdrm2',
      'libgbm1',
      'libglib2.0-0',
      'libnspr4',
      'libnss3',
      'libpango-1.0-0',
      'libx11-6',
      'libxcb1',
      'libxcomposite1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxkbcommon0',
      'libxrandr2'
    ],
    firefox: [
      'libasound2',
      'libatk1.0-0',
      'libcairo-gobject2',
      'libcairo2',
      'libdbus-1-3',
      'libdbus-glib-1-2',
      'libfontconfig1',
      'libfreetype6',
      'libgdk-pixbuf-2.0-0',
      'libglib2.0-0',
      'libgtk-3-0',
      'libharfbuzz0b',
      'libpango-1.0-0',
      'libpangocairo-1.0-0',
      'libx11-6',
      'libx11-xcb1',
      'libxcb-shm0',
      'libxcb1',
      'libxcomposite1',
      'libxcursor1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxi6',
      'libxrandr2',
      'libxrender1',
      'libxtst6'
    ],
    webkit: [
      'libsoup-3.0-0',
      'gstreamer1.0-libav',
      'gstreamer1.0-plugins-bad',
      'gstreamer1.0-plugins-base',
      'gstreamer1.0-plugins-good',
      'libatk-bridge2.0-0',
      'libatk1.0-0',
      'libcairo2',
      'libdbus-1-3',
      'libdrm2',
      'libegl1',
      'libenchant-2-2',
      'libepoxy0',
      'libevdev2',
      'libfontconfig1',
      'libfreetype6',
      'libgbm1',
      'libgdk-pixbuf-2.0-0',
      'libgles2',
      'libglib2.0-0',
      'libglx0',
      'libgstreamer-gl1.0-0',
      'libgstreamer-plugins-base1.0-0',
      'libgstreamer1.0-0',
      'libgtk-4-1',
      'libgudev-1.0-0',
      'libharfbuzz-icu0',
      'libharfbuzz0b',
      'libhyphen0',
      'libicu72',
      'libjpeg62-turbo',
      'liblcms2-2',
      'libmanette-0.2-0',
      'libnotify4',
      'libopengl0',
      'libopenjp2-7',
      'libopus0',
      'libpango-1.0-0',
      'libpng16-16',
      'libproxy1v5',
      'libsecret-1-0',
      'libwayland-client0',
      'libwayland-egl1',
      'libwayland-server0',
      'libwebp7',
      'libwebpdemux2',
      'libwoff1',
      'libx11-6',
      'libxcomposite1',
      'libxdamage1',
      'libxkbcommon0',
      'libxml2',
      'libxslt1.1',
      'libatomic1',
      'libevent-2.1-7',
      'libavif15',
    ],
    lib2package: {
      'libavif.so.15': 'libavif15',
      'libsoup-3.0.so.0': 'libsoup-3.0-0',
      'libasound.so.2': 'libasound2',
      'libatk-1.0.so.0': 'libatk1.0-0',
      'libatk-bridge-2.0.so.0': 'libatk-bridge2.0-0',
      'libatspi.so.0': 'libatspi2.0-0',
      'libcairo.so.2': 'libcairo2',
      'libcups.so.2': 'libcups2',
      'libdbus-1.so.3': 'libdbus-1-3',
      'libdrm.so.2': 'libdrm2',
      'libgbm.so.1': 'libgbm1',
      'libgio-2.0.so.0': 'libglib2.0-0',
      'libglib-2.0.so.0': 'libglib2.0-0',
      'libgobject-2.0.so.0': 'libglib2.0-0',
      'libnspr4.so': 'libnspr4',
      'libnss3.so': 'libnss3',
      'libnssutil3.so': 'libnss3',
      'libpango-1.0.so.0': 'libpango-1.0-0',
      'libsmime3.so': 'libnss3',
      'libX11.so.6': 'libx11-6',
      'libxcb.so.1': 'libxcb1',
      'libXcomposite.so.1': 'libxcomposite1',
      'libXdamage.so.1': 'libxdamage1',
      'libXext.so.6': 'libxext6',
      'libXfixes.so.3': 'libxfixes3',
      'libxkbcommon.so.0': 'libxkbcommon0',
      'libXrandr.so.2': 'libxrandr2',
      'libgtk-4.so.1': 'libgtk-4-1',
    }
  },
  'debian13-x64': {
    tools: [
      'xvfb',
      'fonts-noto-color-emoji',
      'fonts-unifont',
      'libfontconfig1',
      'libfreetype6',
      'xfonts-scalable',
      'fonts-liberation',
      'fonts-ipafont-gothic',
      'fonts-wqy-zenhei',
      'fonts-tlwg-loma-otf',
      'fonts-freefont-ttf',
    ],
    chromium: [
      'libasound2t64',
      'libatk-bridge2.0-0t64',
      'libatk1.0-0t64',
      'libatspi2.0-0t64',
      'libcairo2',
      'libcups2t64',
      'libdbus-1-3',
      'libdrm2',
      'libgbm1',
      'libglib2.0-0t64',
      'libnspr4',
      'libnss3',
      'libpango-1.0-0',
      'libx11-6',
      'libxcb1',
      'libxcomposite1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxkbcommon0',
      'libxrandr2'
    ],
    firefox: [
      'libasound2',
      'libatk1.0-0t64',
      'libcairo-gobject2',
      'libcairo2',
      'libdbus-1-3',
      'libdbus-glib-1-2',
      'libfontconfig1',
      'libfreetype6',
      'libgdk-pixbuf-2.0-0',
      'libglib2.0-0t64',
      'libgtk-3-0t64',
      'libharfbuzz0b',
      'libpango-1.0-0',
      'libpangocairo-1.0-0',
      'libx11-6',
      'libx11-xcb1',
      'libxcb-shm0',
      'libxcb1',
      'libxcomposite1',
      'libxcursor1',
      'libxdamage1',
      'libxext6',
      'libxfixes3',
      'libxi6',
      'libxrandr2',
      'libxrender1',
      'libxtst6'
    ],
    webkit: [
      'libsoup-3.0-0',
      'gstreamer1.0-libav',
      'gstreamer1.0-plugins-bad',
      'gstreamer1.0-plugins-base',
      'gstreamer1.0-plugins-good',
      'libatk-bridge2.0-0t64',
      'libatk1.0-0t64',
      'libcairo2',
      'libdbus-1-3',
      'libdrm2',
      'libegl1',
      'libenchant-2-2',
      'libepoxy0',
      'libevdev2',
      'libfontconfig1',
      'libfreetype6',
      'libgbm1',
      'libgdk-pixbuf-2.0-0',
      'libgles2',
      'libglib2.0-0t64',
      'libglx0',
      'libgstreamer-gl1.0-0',
      'libgstreamer-plugins-base1.0-0',
      'libgstreamer1.0-0',
      'libgtk-4-1',
      'libgudev-1.0-0',
      'libharfbuzz-icu0',
      'libharfbuzz0b',
      'libhyphen0',
      'libicu76',
      'libjpeg62-turbo',
      'liblcms2-2',
      'libmanette-0.2-0',
      'libnotify4',
      'libopengl0',
      'libopenjp2-7',
      'libopus0',
      'libpango-1.0-0',
      'libpng16-16t64',
      'libproxy1v5',
      'libsecret-1-0',
      'libwayland-client0',
      'libwayland-egl1',
      'libwayland-server0',
      'libwebp7',
      'libwebpdemux2',
      'libwoff1',
      'libx11-6',
      'libxcomposite1',
      'libxdamage1',
      'libxkbcommon0',
      'libxml2',
      'libxslt1.1',
      'libatomic1',
      'libevent-2.1-7t64',
      'libavif16',
    ],
    lib2package: {
      'libicudata.so.74': 'libicu76',
      'libicui18n.so.74': 'libicu76',
      'libicuuc.so.74': 'libicu76',
      'libevent-2.1.so.7': 'libevent-2.1-7t64',
      'libpng16.so.16': 'libpng16-16t64',
      'libgdk-3.so.0': 'libgtk-3-0t64',
      'libgtk-3.so.0': 'libgtk-3-0t64',
      'libavif.so.16': 'libavif16',
      'libsoup-3.0.so.0': 'libsoup-3.0-0',
      'libasound.so.2': 'libasound2t64',
      'libatk-1.0.so.0': 'libatk1.0-0t64',
      'libatk-bridge-2.0.so.0': 'libatk-bridge2.0-0t64',
      'libatspi.so.0': 'libatspi2.0-0t64',
      'libcairo.so.2': 'libcairo2',
      'libcups.so.2': 'libcups2t64',
      'libdbus-1.so.3': 'libdbus-1-3',
      'libdrm.so.2': 'libdrm2',
      'libgbm.so.1': 'libgbm1',
      'libgio-2.0.so.0': 'libglib2.0-0t64',
      'libglib-2.0.so.0': 'libglib2.0-0t64',
      'libgobject-2.0.so.0': 'libglib2.0-0t64',
      'libnspr4.so': 'libnspr4',
      'libnss3.so': 'libnss3',
      'libnssutil3.so': 'libnss3',
      'libpango-1.0.so.0': 'libpango-1.0-0',
      'libsmime3.so': 'libnss3',
      'libX11.so.6': 'libx11-6',
      'libxcb.so.1': 'libxcb1',
      'libXcomposite.so.1': 'libxcomposite1',
      'libXdamage.so.1': 'libxdamage1',
      'libXext.so.6': 'libxext6',
      'libXfixes.so.3': 'libxfixes3',
      'libxkbcommon.so.0': 'libxkbcommon0',
      'libXrandr.so.2': 'libxrandr2',
      'libgtk-4.so.1': 'libgtk-4-1',
    }
  },
};

deps['ubuntu20.04-arm64'] = {
  tools: [...deps['ubuntu20.04-x64'].tools],
  chromium: [...deps['ubuntu20.04-x64'].chromium],
  firefox: [
    ...deps['ubuntu20.04-x64'].firefox,
  ],
  webkit: [
    ...deps['ubuntu20.04-x64'].webkit,
  ],
  lib2package: {
    ...deps['ubuntu20.04-x64'].lib2package,
  },
};

deps['ubuntu22.04-arm64'] = {
  tools: [...deps['ubuntu22.04-x64'].tools],
  chromium: [...deps['ubuntu22.04-x64'].chromium],
  firefox: [
    ...deps['ubuntu22.04-x64'].firefox,
  ],
  webkit: [
    ...deps['ubuntu22.04-x64'].webkit,
  ],
  lib2package: {
    ...deps['ubuntu22.04-x64'].lib2package,
  },
};

deps['ubuntu24.04-arm64'] = {
  tools: [...deps['ubuntu24.04-x64'].tools],
  chromium: [...deps['ubuntu24.04-x64'].chromium],
  firefox: [
    ...deps['ubuntu24.04-x64'].firefox,
  ],
  webkit: [
    ...deps['ubuntu24.04-x64'].webkit,
  ],
  lib2package: {
    ...deps['ubuntu24.04-x64'].lib2package,
  },
};

deps['debian11-arm64'] = {
  tools: [...deps['debian11-x64'].tools],
  chromium: [...deps['debian11-x64'].chromium],
  firefox: [
    ...deps['debian11-x64'].firefox,
  ],
  webkit: [
    ...deps['debian11-x64'].webkit,
  ],
  lib2package: {
    ...deps['debian11-x64'].lib2package,
  },
};

deps['debian12-arm64'] = {
  tools: [...deps['debian12-x64'].tools],
  chromium: [...deps['debian12-x64'].chromium],
  firefox: [
    ...deps['debian12-x64'].firefox,
  ],
  webkit: [
    ...deps['debian12-x64'].webkit,
  ],
  lib2package: {
    ...deps['debian12-x64'].lib2package,
  },
};

deps['debian13-arm64'] = {
  tools: [...deps['debian13-x64'].tools],
  chromium: [...deps['debian13-x64'].chromium],
  firefox: [
    ...deps['debian13-x64'].firefox,
  ],
  webkit: [
    ...deps['debian13-x64'].webkit,
  ],
  lib2package: {
    ...deps['debian13-x64'].lib2package,
  },
};
