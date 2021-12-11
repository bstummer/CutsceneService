--[[

Info: developer.roblox.com/en-us/api-reference/enum/EasingStyle

Source: github.com/EmmanuelOga/easing
By Tweener authors, Yuichi Tateno and Emmanuel Oga
Type annotations added and optimized by Vaschex for CutsceneService

Adapted from
- Tweener's easing functions (Penner's Easing Equations)
- https://code.google.com/p/tweener (jstweener javascript version)


The MIT License
--------
Copyright (c) 2010, Emmanuel Oga.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


Disclaimer for Robert Penner's Easing Equations license:
TERMS OF USE - EASING EQUATIONS
Open source under the BSD License.
Copyright © 2001 Robert Penner
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



t = elapsed time
b = begin
c = change, ending value - beginning value
d = duration
a = amplitud
p = period

]]

type n = number
local s:n = 1.70158

--[[
fun fact, s can be calculated using this function:
local function calc(p)
	p /= 10
	local m = (27*40^2*-27*p+2*(-27*p)^3-9*40*-27*p*-54*p)/(54*40^3)
	local r = (m^2+((3*40*-54*p-(-27*p)^2)/(9*40^2))^3)^0.5
	local s = (-m+r)^(1/3)+(-m-r)^(1/3)-(-27*p)/(3*40)
	return s, 1-(s+3)/(3*s+3)
end
]]

local pow = math.pow
local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin = math.asin

local function Linear(t:n, _:n, _:n, d:n):n
	return t / d
end

local function InQuad(t:n, b:n, c:n, d:n):n
	return c * pow(t / d, 2) + b
end

local function OutQuad(t:n, b:n, c:n, d:n):n
	t /= d
	return -c * t * (t - 2) + b
end

local function InOutQuad(t:n, b:n, c:n, d:n):n
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 2) + b
	else
		return -c / 2 * ((t - 1) * (t - 3) - 1) + b
	end
end

local function OutInQuad(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutQuad(t * 2, b, c / 2, d)
	else
		return InQuad((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function InCubic(t:n, b:n, c:n, d:n):n
	return c * pow(t / d, 3) + b
end

local function OutCubic(t:n, b:n, c:n, d:n):n
	return c * (pow(t / d - 1, 3) + 1) + b
end

local function InOutCubic(t:n, b:n, c:n, d:n):n
	t = t / d * 2
	if t < 1 then
		return c / 2 * t * t * t + b
	else
		t -= 2
		return c / 2 * (t * t * t + 2) + b
	end
end

local function OutInCubic(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutCubic(t * 2, b, c / 2, d)
	else
		return InCubic((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function InQuart(t:n, b:n, c:n, d:n):n
	return c * pow(t / d, 4) + b
end

local function OutQuart(t:n, b:n, c:n, d:n):n
	return -c * (pow(t / d - 1, 4) - 1) + b
end

local function InOutQuart(t:n, b:n, c:n, d:n):n
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 4) + b
	else
		t -= 2
		return -c / 2 * (pow(t, 4) - 2) + b
	end
end

local function OutInQuart(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutQuart(t * 2, b, c / 2, d)
	else
		return InQuart((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function InQuint(t:n, b:n, c:n, d:n):n
	return c * pow(t / d, 5) + b
end

local function OutQuint(t:n, b:n, c:n, d:n):n
	return c * (pow(t / d - 1, 5) + 1) + b
end

local function InOutQuint(t:n, b:n, c:n, d:n):n
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 5) + b
	else
		return c / 2 * (pow(t - 2, 5) + 2) + b
	end
end

local function OutInQuint(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutQuint(t * 2, b, c / 2, d)
	else
		return InQuint((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function InSine(t:n, b:n, c:n, d:n):n
	return -c * cos(t / d * (pi / 2)) + c + b
end

local function OutSine(t:n, b:n, c:n, d:n):n
	return c * sin(t / d * (pi / 2)) + b
end

local function InOutSine(t:n, b:n, c:n, d:n):n
	return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function OutInSine(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutSine(t * 2, b, c / 2, d)
	else
		return InSine((t * 2) -d, b + c / 2, c / 2, d)
	end
end

local function InExpo(t:n, b:n, c:n, d:n):n
	if t == 0 then return b else
		return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
	end
end

local function OutExpo(t:n, b:n, c:n, d:n):n
	if t == d then return b + c else
		return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
	end
end

local function InOutExpo(t:n, b:n, c:n, d:n):n
	if t == 0 then return b end
	if t == d then return b + c end
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
	else
		t = t - 1
		return c / 2 * 1.0005 * (-pow(2, -10 * t) + 2) + b
	end
end

local function OutInExpo(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutExpo(t * 2, b, c / 2, d)
	else
		return InExpo((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function InCirc(t:n, b:n, c:n, d:n):n
	return -c * (sqrt(1 - pow(t / d, 2)) - 1) + b
end

local function OutCirc(t:n, b:n, c:n, d:n):n
	return c * sqrt(1 - pow(t / d - 1, 2)) + b
end

local function InOutCirc(t:n, b:n, c:n, d:n):n
	t = t / d * 2
	if t < 1 then
		return -c / 2 * (sqrt(1 - t * t) - 1) + b
	else
		t = t - 2
		return c / 2 * (sqrt(1 - t * t) + 1) + b
	end
end

local function OutInCirc(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutCirc(t * 2, b, c / 2, d)
	else
		return InCirc((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function InElastic(t:n, b:n, c:n, d:n, a:n, p:n):n
	if t == 0 then return b end
	t /= d
	if t == 1 then return b + c end
	if not p then p = d * 0.3 end
	local s:n
	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end
	t -= 1
	return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

local function OutElastic(t:n, b:n, c:n, d:n, a:n, p:n):n
	if t == 0 then return b end
	t /= d
	if t == 1 then return b + c end
	if not p then p = d * 0.3 end
	local s:n
	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end
	return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

local function InOutElastic(t:n, b:n, c:n, d:n, a:n, p:n):n
	if t == 0 then return b end
	t = t / d * 2
	if t == 2 then return b + c end
	if not p then p = d * (0.3 * 1.5) end
	if not a then a = 0 end
	local s:n
	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c / a)
	end
	if t < 1 then
		t -= 1
		return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
	else
		t -= 1
		return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
	end
end

local function OutInElastic(t:n, b:n, c:n, d:n, a:n, p:n):n
	if t < d / 2 then
		return OutElastic(t * 2, b, c / 2, d, a, p)
	else
		return InElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
	end
end

local function InBack(t:n, b:n, c:n, d:n):n
	t /= d
	return c * t * t * ((s + 1) * t - s) + b
end

local function OutBack(t:n, b:n, c:n, d:n):n
	t = t / d - 1
	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function InOutBack(t:n, b:n, c:n, d:n):n
	t = t / d * 2
	if t < 1 then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	else
		t -= 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end
end

local function OutInBack(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutBack(t * 2, b, c / 2, d)
	else
		return InBack((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function OutBounce(t:n, b:n, c:n, d:n):n
	t /= d
	if t < 0.36363636363636 then
		return c * (7.5625 * t * t) + b
	elseif t < 0.72727272727273 then
		t -= 0.54545454545455
		return c * (7.5625 * t * t + 0.75) + b
	elseif t < 0.90909090909091 then
		t -= 0.81818181818182
		return c * (7.5625 * t * t + 0.9375) + b
	else
		t -= 0.95454545454545
		return c * (7.5625 * t * t + 0.984375) + b
	end
end

local function InBounce(t:n, b:n, c:n, d:n):n
	return c - OutBounce(d - t, 0, c, d) + b
end

local function InOutBounce(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return InBounce(t * 2, 0, c, d) * 0.5 + b
	else
		return OutBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
	end
end

local function OutInBounce(t:n, b:n, c:n, d:n):n
	if t < d / 2 then
		return OutBounce(t * 2, b, c / 2, d)
	else
		return InBounce((t * 2) - d, b + c / 2, c / 2, d)
	end
end

return {
	Linear = Linear,
	InQuad = InQuad,
	OutQuad = OutQuad,
	InOutQuad = InOutQuad,
	OutInQuad = OutInQuad,
	InCubic  = InCubic ,
	OutCubic = OutCubic,
	InOutCubic = InOutCubic,
	OutInCubic = OutInCubic,
	InQuart = InQuart,
	OutQuart = OutQuart,
	InOutQuart = InOutQuart,
	OutInQuart = OutInQuart,
	InQuint = InQuint,
	OutQuint = OutQuint,
	InOutQuint = InOutQuint,
	OutInQuint = OutInQuint,
	InSine = InSine,
	OutSine = OutSine,
	InOutSine = InOutSine,
	OutInSine = OutInSine,
	InExponential = InExpo,
	OutExponential = OutExpo,
	InOutExponential = InOutExpo,
	OutInExponential = OutInExpo,
	InCircular = InCirc,
	OutCircular = OutCirc,
	InOutCircular = InOutCirc,
	OutInCircular = OutInCirc,
	InElastic = InElastic,
	OutElastic = OutElastic,
	InOutElastic = InOutElastic,
	OutInElastic = OutInElastic,
	InBack = InBack,
	OutBack = OutBack,
	InOutBack = InOutBack,
	OutInBack = OutInBack,
	InBounce = InBounce,
	OutBounce = OutBounce,
	InOutBounce = InOutBounce,
	OutInBounce = OutInBounce,
}