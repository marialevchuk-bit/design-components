# Faithful static-HTML rebuild of obIntroArt / obSearchVisual / obJourney (+ obBenefits)
import json,sys
import os; P=json.load(open(os.environ["PATHS_JSON"]))
CARD=P['CARD']; CHIP='M42 56H78a8 8 0 0 1 8 8V108a8 8 0 0 1-8 8H42a8 8 0 0 1-8-8V64a8 8 0 0 1 8-8Z'
LINES='M34 78H86M34 94H86M60 56V78M60 94V116'
PIN='M12 1.5a8 8 0 0 0-8 8c0 5.1 5.6 10.4 7.4 12a.9.9 0 0 0 1.2 0c1.8-1.6 7.4-6.9 7.4-12a8 8 0 0 0-8-8Zm0 5.2a2.8 2.8 0 1 1 0 5.6 2.8 2.8 0 0 1 0-5.6Z'
CHECK='M13.333 4L6 11.333 2.667 8'
KEYFRAMES='''@keyframes ob-up { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
@keyframes ob-pulse { 0% { transform: scale(.82); opacity: .55; } 100% { transform: scale(1.4); opacity: 0; } }
@keyframes ob-pop { 0% { transform: scale(0); } 70% { transform: scale(1.12); } 100% { transform: scale(1); } }
@keyframes ob-fill { from { transform: scaleY(0); } to { transform: scaleY(1); } }
@keyframes ob-drop { 0% { transform: translateY(-60px); opacity: 0; } 60% { opacity: 1; } 100% { transform: translateY(0); opacity: 1; } }
@keyframes ob-sel { to { background: #003DF5; color: #FFFFFF; box-shadow: none; } }'''
def ico(k,color,size):
    return f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+''.join(f'<path d="{d}"/>' for d in P['P'][k])+'</svg>'
def intro_art():
    return f'''<div class="ob-intro" style="position:relative;width:170px;height:170px;display:flex;align-items:center;justify-content:center;">
  <div style="position:absolute;inset:15px;border-radius:9999px;border:2px solid #003DF5;animation:ob-pulse 2.4s ease-out infinite;"></div>
  <div style="position:absolute;inset:15px;border-radius:9999px;border:2px solid #003DF5;animation:ob-pulse 2.4s ease-out 1.2s infinite;"></div>
  <div style="position:relative;width:136px;height:136px;border-radius:9999px;background:#E5EBFE;display:flex;align-items:center;justify-content:center;">
    <svg width="56" height="72" viewBox="0 0 120 156" fill="none" stroke="#003DF5" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"><path d="{CARD}"/><path d="{CHIP}"/><path d="{LINES}"/></svg>
  </div>
</div>'''
def benefits():
    rows=''.join(f'''<div style="display:flex;align-items:center;gap:12px;animation:ob-up 320ms ease {0.25+i*0.15:.2f}s both;"><div style="width:32px;height:32px;border-radius:9999px;flex:0 0 auto;background:#E5EBFE;display:flex;align-items:center;justify-content:center;"><svg width="17" height="17" viewBox="0 0 16 16" fill="none" stroke="#003DF5" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="{CHECK}"/></svg></div><div style="font-size:19px;font-weight:600;color:#0A0F24;">{b}</div></div>''' for i,b in enumerate(['No roaming charges','Online as soon as you land','Your number stays on for calls and SMS']))
    return f'<div style="display:flex;flex-direction:column;gap:18px;align-self:center;">{rows}</div>'
def search():
    chip=lambda label,i,sel: f'<div class="chip" style="min-width:76px;box-sizing:border-box;text-align:center;padding:14px 18px;border-radius:12px;background:#FFFFFF;box-shadow:inset 0 0 0 1px #D5D8E0;font-size:18px;font-weight:700;color:#0A0F24;animation:ob-up 320ms ease {1.0+i*0.15:.2f}s both{", ob-sel 260ms ease 2.1s forwards" if sel else ""};">{label}</div>'
    return f'''<div class="ob-search" style="display:flex;flex-direction:column;align-items:center;gap:22px;">
  <div style="position:relative;width:140px;height:140px;">
    <svg width="140" height="140" viewBox="0 0 120 120" fill="none" style="display:block"><circle cx="60" cy="60" r="55" fill="#E5EBFE"/><path d="{P['FC_LAND']}" fill="#003DF5" stroke="#003DF5" stroke-width="0.6" stroke-linejoin="round"/><circle cx="60" cy="60" r="55" stroke="#003DF5" stroke-width="2.4"/></svg>
    <div class="pin" style="position:absolute;left:61px;top:77px;line-height:0;animation:ob-drop 620ms cubic-bezier(.3,1.5,.5,1) .3s both;"><svg width="32" height="32" viewBox="0 0 24 24" fill="#E5EBFE" stroke="none"><path fill-rule="evenodd" d="{PIN}"/></svg></div>
  </div>
  <div style="display:flex;gap:12px;">{chip('3 GB',0,False)}{chip('5 GB',1,True)}{chip('10 GB',2,False)}</div>
</div>'''
JR=[('dl','Activate your eSIM','Add it to your phone in one tap'),('gear','Complete setup','Name it and turn it on in Settings'),('plane','Connect at your destination','Turn it on when you land')]
def journey():
    out=[]
    for i,(k,t,s) in enumerate(JR):
        d=0.35+i*0.7
        line=f'<div style="position:relative;width:2px;flex:1 1 auto;min-height:26px;background:#D5D8E0;margin:4px 0;"><div style="position:absolute;inset:0;background:#003DF5;transform-origin:top;animation:ob-fill 380ms ease {d+0.3:.2f}s both;"></div></div>' if i<2 else ''
        out.append(f'''<div style="display:flex;gap:14px;align-items:stretch;">
  <div style="display:flex;flex-direction:column;align-items:center;flex:0 0 auto;">
    <div style="position:relative;width:46px;height:46px;border-radius:9999px;box-shadow:inset 0 0 0 2px #D5D8E0;display:flex;align-items:center;justify-content:center;">{ico(k,'#8A90A6',22)}<div style="position:absolute;inset:0;border-radius:9999px;background:#003DF5;display:flex;align-items:center;justify-content:center;animation:ob-pop 420ms cubic-bezier(.3,1.4,.5,1) {d:.2f}s both;">{ico(k,'#FFFFFF',22)}</div></div>{line}
  </div>
  <div class="jt" style="display:flex;flex-direction:column;gap:2px;padding-top:4px;padding-bottom:{'18px' if i<2 else '0'};animation:ob-up 320ms ease {d-0.1:.2f}s both;"><div style="font-size:19px;font-weight:700;color:#0A0F24;">{t}</div><div style="font-size:16px;color:#5C6480;">{s}</div></div>
</div>''')
    return '<div class="ob-journey" style="display:flex;flex-direction:column;align-self:stretch;padding:0 8px;">'+''.join(out)+'</div>'
