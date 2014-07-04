function cirobj = PassiveCreateCircleObject(scrX,scrY,spinner,gamble,outcome,angle)
    
    cirobj.outcome = outcome;
    cirobj.gamble = gamble;
    
    cirobj.diameter = 0.25*scrX;    
    cirobj.startX = (scrX-cirobj.diameter)/2;
    cirobj.startY = (.70*scrY-cirobj.diameter)/2;
    cirobj.endX = cirobj.startX+cirobj.diameter;
    cirobj.endY = cirobj.startY+cirobj.diameter;
    
    cirobj.linewidth = 5;
    cirobj.linecolor = 225;
    cirobj.wincolor = [200 200 0];
    
    cirobj.position = [cirobj.startX cirobj.startY cirobj.endX cirobj.endY];
    cirobj.degree = angle;
    cirobj.startframe = 270;
    
    % must divide 360 
    cirobj.velocity = 15;
    cirobj.frames = 360/cirobj.velocity;
    
    if spinner
        lineY = [];
        lineX = [];
        line2Y = [];
        line2X = [];

        for i = 1:cirobj.frames
            lineY = [lineY sind(mod(cirobj.startframe+(cirobj.velocity*(i-1))-cirobj.degree/2,360))*cirobj.diameter/2];
            lineX = [lineX cosd(mod(cirobj.startframe+(cirobj.velocity*(i-1))-cirobj.degree/2,360))*cirobj.diameter/2];
            line2Y = [line2Y sind(mod(cirobj.startframe+(cirobj.velocity*(i-1))+cirobj.degree/2,360))*cirobj.diameter/2];
            line2X = [line2X cosd(mod(cirobj.startframe+(cirobj.velocity*(i-1))+cirobj.degree/2,360))*cirobj.diameter/2];
        end

        cirobj.lineY = lineY;
        cirobj.lineX = lineX;
        cirobj.line2Y = line2Y;
        cirobj.line2X = line2X;
    end
    
end