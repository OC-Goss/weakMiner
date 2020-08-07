--[[
NOTE: Currently not well-tested!

3D cartesian vector
Written by weakman54

Modified from it's original 2D form into 3D, expect some copy paste bugs

Use as:
[local] Vector = require "Vector"
myVec = Vector(2, 4, 5)

uses x, y, and z positions as the internal representation,
if the vector is used primarily as a polar vector, consider using
the polar version. (the polar vector class does not exist yet)
--]]


-- Localize functions to improve performance
local sqrt, atan2, sin, cos = math.sqrt, math.atan2, math.sin, math.cos
local ceil, floor = math.ceil, math.floor

local Vector = {}
Vector.__index = Vector
Vector.__version = "1.1"


-----------------------------------------------------------
-- Constructors and helpers: ------------------------------
function Vector.new(x, y, z)
  return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, Vector)
end

function Vector:clone()
  return Vector.new(self.x, self.y, self.z)
end

function Vector:unpack()
  return self.x, self.y, self.z
end

function Vector.__tostring(a)
  return "(" .. a.x .. ", " .. a.y .. ", " .. a.z .. ")"
end

function Vector.isVector(a)
  return getmetatable(a) == Vector -- NOTE: this means that only this vector "class" returns true, so other objects that might work as vectors won't return true
end


-----------------------------------------------------------
-- Arithmetic operators: ----------------------------------
function Vector.__add(a, b)
  if type(a) == "number" then
    return Vector.new(b.x + a, b.y + a, b.z + a)
    
  elseif type(b) == "number" then
    return Vector.new(a.x + b, a.y + b, a.z + b)
    
  else
    return Vector.new(a.x + b.x, a.y + b.y, a.z + b.z)
    
  end
end

function Vector.__sub(a, b)
  if type(a) == "number" then
    error("can't subtract vector from number!", 2)
--    return Vector.new(b.x - a, b.y - a, b.z - a)
    
  elseif type(b) == "number" then
    return Vector.new(a.x - b, a.y - b, a.z - b)
    
  else
    return Vector.new(a.x - b.x, a.y - b.y, a.z - b.z)
    
  end
end

function Vector.__mul(a, b)
  if type(a) == "number" then
    return Vector.new(b.x * a, b.y * a, b.z * a)
    
  elseif type(b) == "number" then
    return Vector.new(a.x * b, a.y * b, a.z * b)
    
  else
    error("Multiplication operator between vector not implemented! (use mult_elementwise, mult_whatever (TODO: make these functions and such...))", 2)
--    return Vector.new(a.x * b.x, a.y * b.y, a.z * b.z)
    
  end
end

function Vector.__div(a, b)
  if type(a) == "number" then
    error("can't divide number with vector!", 2)
--    return Vector.new(b.x / a, b.y / a, b.z / a)
    
  elseif type(b) == "number" then
    return Vector.new(a.x / b, a.y / b, a.z / b)
    
  else
    error("can't divide two vectors!", 2)
--    return Vector.new(a.x / b.x, a.y / b.y, a.z / b.z)
    
  end
end


function Vector.__unm(a)
  return Vector.new(-a.x, -a.y, -a.z)
end



-----------------------------------------------------------
-- Comparison operators: ----------------------------------
function Vector.__eq(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

function Vector.__lt(a, b)
  error("Can't use less than or greater than operators with vectors!", 2)
--  return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function Vector.__le(a, b)
  error("Can't use less than or greater than operators with vectors!", 2)
--  return a.x <= b.x and a.y <= b.y
end




-----------------------------------------------------------
-- Magnitude(length) operations: --------------------------
function Vector:isZero()
  return self.x == 0 and self.y == 0 and self.z == 0
end

function Vector:len()
  return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end
Vector.magnitude = Vector.len

function Vector:lenSq()
  return self.x * self.x + self.y * self.y + self.z * self.z
end

function Vector.distance(a, b)
  return (b - a):len()
end

function Vector.distanceSq(a, b)
 return (b - a):lenSq()
end


function Vector:distanceTo(b)
  return (b - self):len()
end

function Vector.distanceSqTo(b)
 return (b - self):lenSq()
end


function Vector:normalized()
  return self / self:len()
end

function Vector:normalizeInPlace()
  local len = self:len()
  self.x = self.x / len
  self.y = self.y / len
  self.z = self.z / len
  return self
end



-----------------------------------------------------------
-- Rotation operations (uses radians): --------------------
function Vector:angle()
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return atan2(self.y, self.x)
end

function Vector:setRotation(angle)
  error("NOT IMPLEMENTED FOR VECTOR3!")
  local newX = cos(angle)
  local newY = sin(angle)
  local mag = self:len()

  self.x = newX * mag
  self.y = newY * mag
end

function Vector:rotate(phi)
  error("NOT IMPLEMENTED FOR VECTOR3!")
  local c = cos(phi)
  local s = sin(phi)

  self.x, self.y =
  c * self.x - s * self.y,
  s * self.x + c * self.y

  return self
end

function Vector:rotated(phi)
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return self:clone():rotate(phi)
end



-----------------------------------------------------------
-- Other vector operations: -------------------------------
function Vector:perpendicular()
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return Vector.new(-self.y, self.x)
end

function Vector:projectOn(other)
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return (self:dot(other)) * other / other:lenSq()
end


function Vector:rejectionOn(other)
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return self - self:projectOn(other)
end


-- TODO: implement 3D specific operations (can't remember what they are called tho...)


-- NOTE: this could also be called cross, but is technically incorrect
--       and has ambiguous interpretations
-- the determinant of the matrix described by the two vectors
-- Equals the area of the parallelogram spanned by the two vectors.
function Vector:det(other)
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return self.x * other.y - self.y * other.x
end

function Vector:dot(other)
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return self.x * other.x + self.y * other.y
end



-- Ceil and floor operators: ----------
-- This calls math.ceil/floor on each component separately.
-- This is mostly useful for easy comparison between cartesian vectors.
function Vector:ceilInPlace()
  self.x = ceil(self.x)
  self.y = ceil(self.y)
  self.z = ceil(self.z)
  return self
end

function Vector:ceiled()
  return self:clone():ceil()
end

function Vector:floorInPlace()
  self.x = floor(self.x)
  self.y = floor(self.y)
  self.z = floor(self.z)
  return self
end

function Vector:floored()
  return self:clone():floor()
end



-- Conversion operators: ----------
-- Note that the conversion to the same type is equated with clone,
-- this is to unify the interface for both types.
-- Also note that conversion to the other type currently does not
-- associate the returned table with any metatable, so it cannot be
-- used in any operations.
function Vector:asPolar()
  error("NOT IMPLEMENTED FOR VECTOR3!")
  return {
    r = self:len(),
    a = self:angle(),
  }
end

Vector.asCartesian = Vector.clone



setmetatable(Vector, { __call = function(_, ...) return Vector.new(...) end })

return Vector



--[[
MIT License

Copyright (c) 2020 weakman54 (enkiigm@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]