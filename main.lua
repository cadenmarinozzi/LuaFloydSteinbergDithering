local inputPath = arg[2];
local grayScale = arg[3];

local function round(x)
    return x + (2 ^ 52 + 2 ^ 51) - (2 ^ 52 + 2 ^ 51);
end

local function closestPaletteColor(steps, value)
    return round((steps * value) / 255) * math.floor(255 / steps);
end

local function averageColor(r, g, b)
    return (r + g + b) / 3;
end

local function ditherImage(imageData, steps)
    local width, height = imageData:getWidth(), imageData:getHeight();

    local function getPixel(x, y)
        local r, g, b, a = imageData:getPixel(x, y);

        -- Love2d uses values from 0 to 1, so we need to multiply by 255
        return r * 255, g * 255, b * 255, a * 255;
    end

    local function setPixel(x, y, r, g, b, a)
        -- Divide by 255 to get the value from 0 to 1
        imageData:setPixel(x, y, r / 255, g / 255, b / 255, a / 255);
    end

    local function addQuantError(x, y, factor, quantErrorR, quantErrorG, quantErrorB)
        -- Bounds check
        if (x < 0 or x >= width or y < 0 or y >= height) then
            return;
        end

        local r, g, b, a = getPixel(x, y);

        if (grayScale) then
            local gray = averageColor(r, g, b);
            r = gray;
            g = gray;
            b = gray;
        end

        setPixel(x, y, r + quantErrorR * factor, g + quantErrorG * factor, b + quantErrorB * factor, a);
    end

    for y = 1, height - 1 do
        for x = 1, width - 1 do
            local r, g, b, a = getPixel(x, y);

            if (grayScale) then
                r, g, b = averageColor(r, g, b), averageColor(r, g, b), averageColor(r, g, b);
            end

            local newR = closestPaletteColor(steps, r);
            local newG = closestPaletteColor(steps, g);
            local newB = closestPaletteColor(steps, b);

            setPixel(x, y, newR, newG, newB, a);

            local quantErrorR = r - newR;
            local quantErrorG = g - newG;
            local quantErrorB = b - newB;

            addQuantError(x + 1, y, 7 / 16, quantErrorR, quantErrorG, quantErrorB);
            addQuantError(x - 1, y + 1, 3 / 16, quantErrorR, quantErrorG, quantErrorB);
            addQuantError(x, y + 1, 5 / 16, quantErrorR, quantErrorG, quantErrorB);
            addQuantError(x + 1, y + 1, 1 / 16, quantErrorR, quantErrorG, quantErrorB);
        end
    end

    return imageData;
end

local outputImage;

function love.load()
    local imageData = love.image.newImageData(inputPath);
    local ditheredImage = ditherImage(imageData, 1);

    outputImage = love.graphics.newImage(ditheredImage);
end

function love.draw()
    love.graphics.draw(outputImage);
end