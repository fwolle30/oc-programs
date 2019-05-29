if (type(math.round) == "nil") then
    function math.round(value, exponent)
        if (type(value) ~= "number") then
            error("Invalid argument for \"value\". Expected \"number\" got \"" .. type(value) .. "\".");
            return;
        end

        if (type(exponent) == "nil") then
            exponent = 2;
        elseif (type(exponent) ~= "number") then
            error("Invalid argument for \"exponent\". Expected \"number\" got \"" .. type(exponent) .. "\".");
            return;
        end

        local exp = 10 ^ math.abs(exponent);
        local result = math.floor((value * exp) + 0.5) / exp;

        return result;
    end
end