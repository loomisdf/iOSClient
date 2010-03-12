#ifndef __ALIGNMENT_PATTERN_H__
#define __ALIGNMENT_PATTERN_H__

/*
 *  AlignmentPattern.h
 *  zxing
 *
 *  Created by Christian Brunschen on 13/05/2008.
 *  Copyright 2008 ZXing authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "../../ResultPoint.h"
#include <cmath>

namespace qrcode {
  namespace detector {
    using namespace std;
    using namespace common;
    
    class AlignmentPattern : public ResultPoint {
    private:
      float posX_;
      float posY_;
      float estimatedModuleSize_;
      
    public:
      AlignmentPattern(float posX, float posY, float estimatedModuleSize) :
      posX_(posX), posY_(posY), estimatedModuleSize_(estimatedModuleSize) { }
      float getX() { return posX_; }
      float getY() { return posY_; }
      bool aboutEquals(float moduleSize, float i, float j) {
        return
          abs(i - posY_) <= moduleSize &&
          abs(j - posX_) <= moduleSize &&
          (abs(moduleSize - estimatedModuleSize_) <= 1.0f ||
           abs(moduleSize - estimatedModuleSize_) / estimatedModuleSize_ <= 0.1f);
      }
    };
  }
}

#endif // __ALIGNMENT_PATTERN_H__
