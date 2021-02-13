float sph_dist(in vec3 pos, in vec3 cen, in float r){
    return length(pos - cen) - r;

}

float box_dist(vec3 pos, vec3 cen, vec3 r){
    vec3 q = abs(pos - cen) - r;
    
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);

}

/*float map(in vec3 pos){
    
    float disp =  sin(5.0*pos.x) * sin(5.0*pos.y) * sin(5.0*pos.z) * 0.25;

    float d = sph_dist(pos, vec3(0.0, 0.0, 0.0),3.0);
    
    float d2 = pos.y - (-3.0);
    
    float d3 = box_dist(pos, vec3(0.0), vec3(1.0));
    
    return min(d2, d+disp);
}*/

vec2 map(in vec3 pos){
    
    float disp =  sin(5.0*pos.x) * sin(5.0*pos.y) * sin(5.0*pos.z) * 0.25;
    float an2 = 10.0 * iTime/10.0;
    float d = sph_dist(pos, vec3(cos(an2), 0.0, sin(an2)), sin(an2) + cos(an2) + 1.5);
    
    float d2 = pos.y - (-3.0);
    
    float d3 = box_dist(pos, vec3(0.0), vec3(1.0));
    if (min(d2, d+disp) == d2){
        //return vec2(d2, 1.0);
    }
    
    return vec2(d+disp, 2.0);
}



vec3 normal(in vec3 pos){

    const vec3 eps = vec3(0.0001, 0.0, 0.0);
    
    
    
    float grad_x = map(pos + eps.xyy).x - map(pos - eps.xyy).x;
    float grad_y = map(pos + eps.yxy).x - map(pos - eps.yxy).x;
    float grad_z = map(pos + eps.yyx).x - map(pos - eps.yyx).x;
    
    
    
    return normalize(vec3(grad_x, grad_y, grad_z));



}

float diffuse_light(in vec3 pos, in vec3 cen){
    
    vec3 nor = normal(pos);
    vec3 dir_to_light = normalize(pos - cen);
    float diff_intens = max(0.0, dot(nor, dir_to_light));
    
    return diff_intens;

}


float phong_light(in vec3 pos, in vec3 cen, in vec3 ro){
    
    const float specPower = 30.0;
    vec3 n = normal(pos);
    vec3 l = normalize(pos - cen);
    vec3 v = normalize(pos - ro);
    vec3 r = reflect(v, n);
    float phong_light = pow ( max ( dot ( l, r ), 0.0 ), specPower );
    return phong_light;

}
float CookTorrance(in vec3 pos, in vec3 cen, in vec3 ro){
     const float m = 0.5;
    vec3 n = normal(pos);
    vec3 l = normalize(pos - cen);
    vec3 v = normalize(pos - ro);
    vec3 h = normalize(v + l);
    
    float nl    = dot( n, l );
    float nv    = dot( n, v);
    float nh    = max( dot( n, h ), 1.0e-7 );
    float vh    = dot( v, h );
    
    float tmp = 1.0 / (4.0 * m * m * pow(nh, 4.0));
    float d = tmp * exp((nh*nh - 1.0)/(m*m*nh*nh));
    tmp = 1.0 / (1.0 + vh);
    float f = tmp + (1.0 - pow(nv, 5.0)) *(1.0 - tmp);
    tmp = 2.0 * nh * nv / vh;
    float g = min(1.0, min(tmp, 2.0 * nh * nl/ vh));
    
    float I = f * g * d /  nv;
    
    
    return I;
    
}


float softshadow( in vec3 ro, in vec3 rd )
{
    float mint = 0.0;
    float maxt = 100.0;
       float k = 2.0;
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t).x;
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}


vec2 rayMarch(in vec3 ro, in vec3 rd){
    
    const float max_dist = 100.0;
    const float min_dist = 0.01;
    const int max_step = 1000;
    float total_dist = 0.0;
    
    for(int i = 0; i < max_step; i++){
        
        
        vec3 cur_pos = ro + total_dist * rd;
        
        vec2 cur_dist = map(cur_pos);
        
        if(cur_dist.x < min_dist){
            cur_dist.x = total_dist;
            return cur_dist;
        }
        
        if(cur_dist.x > max_dist){
            break;
        }
        total_dist += cur_dist.x;
    }
    
    return vec2(-1.0);
    
}

//(vec3(0.7, 0.0, 0.0) * diffuse_light(cur_pos, light_pos) +
                   // vec3(0.7, 0.7, 0.7) * phong_light(cur_pos, light_pos, ro));


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0 * fragCoord - iResolution.xy)/iResolution.y; //получаем пиксель

    //float an = 10.0 * iMouse.x/iResolution.x;

    float an = 10.0 * iTime/iResolution.x;
    
    vec3 ro = vec3(7.0*sin(an), 0.0, 7.0* cos(an)); //положение камеры



    vec3 ta = vec3(0.0, 0.0, 0.0); // target for camera


    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize( cross(ww, vec3(0,1,0)));
    vec3 vv = normalize( cross(uu, ww));



    vec3 rd = normalize(uv.x*uu + uv.y*vv + ww);

    
    
    
    vec2 obj = rayMarch(ro, rd);
    
    vec3 obj_pos = ro + obj.x * rd;
    float an2 = 10.0 * iTime/10.0;
    vec3 light_pos = vec3(sin(an2), -7.0, 7.0 * cos(an2));
    
    vec3 light = (vec3(0.3, 0.2, 0.7) * diffuse_light(obj_pos, light_pos) +
                  vec3(1.7, 0.7, 0.7) * phong_light(obj_pos, light_pos, ro));
    
    vec3 col =  light;

    // Output to screen
    fragColor = vec4(col,1.0);
}
