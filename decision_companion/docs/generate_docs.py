"""
Documentation Generator Script
Converts Markdown files to PDF and generates PNG diagrams
Enhanced with better visuals, gradients, and professional styling
"""

import os
from fpdf import FPDF
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import re
import math

# Configuration
DOCS_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(DOCS_DIR, 'output')
PDF_DIR = os.path.join(OUTPUT_DIR, 'pdf')
PNG_DIR = os.path.join(OUTPUT_DIR, 'png')

# Create output directories
os.makedirs(PDF_DIR, exist_ok=True)
os.makedirs(PNG_DIR, exist_ok=True)

# Enhanced Color Palette
COLORS = {
    'primary': '#2563EB',      # Blue
    'secondary': '#7C3AED',    # Purple
    'success': '#10B981',      # Green
    'warning': '#F59E0B',      # Orange
    'danger': '#EF4444',       # Red
    'info': '#06B6D4',         # Cyan
    'dark': '#1F2937',         # Dark gray
    'light': '#F3F4F6',        # Light gray
    'white': '#FFFFFF',
    'gradient_start': '#667EEA',
    'gradient_end': '#764BA2',
}

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def draw_rounded_rectangle(draw, coords, radius, fill=None, outline=None, width=1):
    """Draw a rounded rectangle"""
    x1, y1, x2, y2 = coords
    
    if fill:
        # Main rectangle
        draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
        draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
        # Corners
        draw.ellipse([x1, y1, x1 + 2*radius, y1 + 2*radius], fill=fill)
        draw.ellipse([x2 - 2*radius, y1, x2, y1 + 2*radius], fill=fill)
        draw.ellipse([x1, y2 - 2*radius, x1 + 2*radius, y2], fill=fill)
        draw.ellipse([x2 - 2*radius, y2 - 2*radius, x2, y2], fill=fill)
    
    if outline:
        # Draw outline arcs and lines
        draw.arc([x1, y1, x1 + 2*radius, y1 + 2*radius], 180, 270, fill=outline, width=width)
        draw.arc([x2 - 2*radius, y1, x2, y1 + 2*radius], 270, 360, fill=outline, width=width)
        draw.arc([x1, y2 - 2*radius, x1 + 2*radius, y2], 90, 180, fill=outline, width=width)
        draw.arc([x2 - 2*radius, y2 - 2*radius, x2, y2], 0, 90, fill=outline, width=width)
        draw.line([x1 + radius, y1, x2 - radius, y1], fill=outline, width=width)
        draw.line([x1 + radius, y2, x2 - radius, y2], fill=outline, width=width)
        draw.line([x1, y1 + radius, x1, y2 - radius], fill=outline, width=width)
        draw.line([x2, y1 + radius, x2, y2 - radius], fill=outline, width=width)

def draw_shadow_box(img, draw, coords, radius, fill, shadow_offset=4):
    """Draw a box with shadow effect"""
    x1, y1, x2, y2 = coords
    # Shadow
    shadow_color = '#00000030'
    draw_rounded_rectangle(draw, [x1+shadow_offset, y1+shadow_offset, x2+shadow_offset, y2+shadow_offset], 
                          radius, fill='#D1D5DB')
    # Main box
    draw_rounded_rectangle(draw, coords, radius, fill=fill, outline='#E5E7EB', width=1)

def draw_gradient_header(img, y_start, y_end, color1, color2):
    """Draw a gradient background"""
    width = img.width
    for y in range(y_start, y_end):
        ratio = (y - y_start) / (y_end - y_start)
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        for x in range(width):
            img.putpixel((x, y), (r, g, b))

def draw_arrow(draw, start, end, color, width=2, arrow_size=10):
    """Draw an arrow from start to end point"""
    x1, y1 = start
    x2, y2 = end
    
    # Draw line
    draw.line([x1, y1, x2, y2], fill=color, width=width)
    
    # Calculate arrow head
    angle = math.atan2(y2 - y1, x2 - x1)
    
    # Arrow head points
    arrow_p1 = (x2 - arrow_size * math.cos(angle - math.pi/6),
                y2 - arrow_size * math.sin(angle - math.pi/6))
    arrow_p2 = (x2 - arrow_size * math.cos(angle + math.pi/6),
                y2 - arrow_size * math.sin(angle + math.pi/6))
    
    draw.polygon([(x2, y2), arrow_p1, arrow_p2], fill=color)

def get_fonts():
    """Get fonts with fallback to default"""
    try:
        return {
            'title': ImageFont.truetype("arial.ttf", 28),
            'subtitle': ImageFont.truetype("arial.ttf", 20),
            'heading': ImageFont.truetype("arial.ttf", 16),
            'body': ImageFont.truetype("arial.ttf", 13),
            'small': ImageFont.truetype("arial.ttf", 11),
            'tiny': ImageFont.truetype("arial.ttf", 9),
        }
    except:
        default = ImageFont.load_default()
        return {k: default for k in ['title', 'subtitle', 'heading', 'body', 'small', 'tiny']}


class MarkdownPDF(FPDF):
    """Custom PDF class for Markdown conversion"""
    
    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=15)
        
    def header(self):
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(100, 100, 100)
        self.cell(0, 10, 'Decision Companion - Documentation', 0, 0, 'C')
        self.ln(15)
        
    def footer(self):
        self.set_y(-15)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')
    
    def chapter_title(self, title):
        self.set_font('Helvetica', 'B', 16)
        self.set_text_color(33, 37, 41)
        self.cell(0, 10, title, 0, 1, 'L')
        self.ln(4)
        
    def section_title(self, title):
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(52, 58, 64)
        self.cell(0, 10, title, 0, 1, 'L')
        self.ln(2)
        
    def subsection_title(self, title):
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(73, 80, 87)
        self.cell(0, 8, title, 0, 1, 'L')
        self.ln(2)
        
    def body_text(self, text):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(33, 37, 41)
        self.multi_cell(0, 6, text)
        self.ln(2)
        
    def code_block(self, code):
        self.set_font('Courier', '', 8)
        self.set_fill_color(248, 249, 250)
        self.set_text_color(33, 37, 41)
        
        # Split code into lines and handle each
        lines = code.split('\n')
        for line in lines:
            # Truncate long lines
            if len(line) > 100:
                line = line[:97] + '...'
            self.cell(0, 5, line, 0, 1, 'L', fill=True)
        self.ln(4)
        
    def table_row(self, cells, is_header=False):
        if is_header:
            self.set_font('Helvetica', 'B', 9)
            self.set_fill_color(233, 236, 239)
        else:
            self.set_font('Helvetica', '', 9)
            self.set_fill_color(255, 255, 255)
        
        col_width = (self.w - 20) / len(cells) if cells else self.w - 20
        for cell in cells:
            cell_text = str(cell)[:30] if len(str(cell)) > 30 else str(cell)
            self.cell(col_width, 7, cell_text, 1, 0, 'L', fill=is_header)
        self.ln()


def parse_markdown(content):
    """Parse markdown content into structured elements"""
    elements = []
    lines = content.split('\n')
    i = 0
    in_code_block = False
    code_content = []
    in_table = False
    table_rows = []
    
    while i < len(lines):
        line = lines[i]
        
        # Code blocks
        if line.strip().startswith('```'):
            if in_code_block:
                elements.append(('code', '\n'.join(code_content)))
                code_content = []
                in_code_block = False
            else:
                in_code_block = True
            i += 1
            continue
            
        if in_code_block:
            code_content.append(line)
            i += 1
            continue
        
        # Tables
        if '|' in line and not line.strip().startswith('#'):
            if line.strip().replace('-', '').replace('|', '').replace(' ', '') == '':
                # Separator line, skip
                i += 1
                continue
            cells = [c.strip() for c in line.split('|') if c.strip()]
            if cells:
                if not in_table:
                    in_table = True
                    elements.append(('table_header', cells))
                else:
                    elements.append(('table_row', cells))
            i += 1
            continue
        else:
            in_table = False
        
        # Headers
        if line.startswith('# '):
            elements.append(('h1', line[2:].strip()))
        elif line.startswith('## '):
            elements.append(('h2', line[3:].strip()))
        elif line.startswith('### '):
            elements.append(('h3', line[4:].strip()))
        elif line.startswith('#### '):
            elements.append(('h4', line[5:].strip()))
        elif line.strip().startswith('- ') or line.strip().startswith('* '):
            elements.append(('bullet', line.strip()[2:]))
        elif line.strip().startswith(tuple(f'{n}.' for n in range(1, 20))):
            elements.append(('numbered', line.strip()))
        elif line.strip() == '---':
            elements.append(('hr', ''))
        elif line.strip():
            elements.append(('text', line.strip()))
        
        i += 1
    
    return elements


def convert_md_to_pdf(md_file, pdf_file):
    """Convert a markdown file to PDF"""
    print(f"Converting {md_file} to PDF...")
    
    with open(md_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    elements = parse_markdown(content)
    
    pdf = MarkdownPDF()
    pdf.add_page()
    
    for elem_type, elem_content in elements:
        try:
            if elem_type == 'h1':
                pdf.chapter_title(elem_content)
            elif elem_type == 'h2':
                pdf.section_title(elem_content)
            elif elem_type == 'h3':
                pdf.subsection_title(elem_content)
            elif elem_type == 'h4':
                pdf.set_font('Helvetica', 'B', 11)
                pdf.cell(0, 7, elem_content, 0, 1)
                pdf.ln(1)
            elif elem_type == 'text':
                pdf.body_text(elem_content)
            elif elem_type == 'bullet':
                pdf.set_font('Helvetica', '', 10)
                pdf.cell(5, 6, chr(149), 0, 0)  # Bullet character
                pdf.multi_cell(0, 6, elem_content)
            elif elem_type == 'numbered':
                pdf.set_font('Helvetica', '', 10)
                pdf.multi_cell(0, 6, elem_content)
            elif elem_type == 'code':
                pdf.code_block(elem_content)
            elif elem_type == 'table_header':
                pdf.table_row(elem_content, is_header=True)
            elif elem_type == 'table_row':
                pdf.table_row(elem_content, is_header=False)
            elif elem_type == 'hr':
                pdf.ln(5)
                pdf.set_draw_color(200, 200, 200)
                pdf.line(10, pdf.get_y(), pdf.w - 10, pdf.get_y())
                pdf.ln(5)
        except Exception as e:
            print(f"  Warning: Could not process element {elem_type}: {e}")
            continue
    
    pdf.output(pdf_file)
    print(f"  Created: {pdf_file}")


def create_erd_png():
    """Create enhanced ERD diagram as PNG"""
    print("Creating ERD diagram PNG...")
    
    width, height = 1800, 1300
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Draw gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#667EEA'), hex_to_rgb('#764BA2'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 250, 25), "Decision Companion - Entity Relationship Diagram", 
              fill='#FFFFFF', font=fonts['title'])
    
    # Entity configurations with colors
    entity_configs = {
        'User': {'x': 80, 'y': 120, 'color': '#3B82F6', 'bg': '#EFF6FF'},
        'UserSettings': {'x': 360, 'y': 120, 'color': '#8B5CF6', 'bg': '#F5F3FF'},
        'ActivityLog': {'x': 640, 'y': 120, 'color': '#EC4899', 'bg': '#FDF2F8'},
        'Decision': {'x': 80, 'y': 420, 'color': '#10B981', 'bg': '#ECFDF5'},
        'DecisionOption': {'x': 360, 'y': 420, 'color': '#F59E0B', 'bg': '#FFFBEB'},
        'Factor': {'x': 640, 'y': 420, 'color': '#EF4444', 'bg': '#FEF2F2'},
        'FactorScore': {'x': 920, 'y': 420, 'color': '#06B6D4', 'bg': '#ECFEFF'},
        'Result': {'x': 80, 'y': 720, 'color': '#84CC16', 'bg': '#F7FEE7'},
        'FactorTemplate': {'x': 360, 'y': 720, 'color': '#F97316', 'bg': '#FFF7ED'},
        'Feedback': {'x': 640, 'y': 720, 'color': '#A855F7', 'bg': '#FAF5FF'},
        'AIParameter': {'x': 920, 'y': 720, 'color': '#14B8A6', 'bg': '#F0FDFA'},
    }
    
    entities_data = {
        'User': ['id (PK) UUID', 'email VARCHAR', 'name VARCHAR', 'password_hash', 'role ENUM', 'is_guest BOOL', 'is_active BOOL', 'created_at'],
        'UserSettings': ['id (PK)', 'user_id (FK)', 'theme', 'notifications', 'language'],
        'ActivityLog': ['id (PK)', 'user_id (FK)', 'action', 'description', 'ip_address', 'created_at'],
        'Decision': ['id (PK)', 'user_id (FK)', 'title', 'description', 'status', 'confidence', 'created_at'],
        'DecisionOption': ['id (PK)', 'decision_id (FK)', 'name', 'description', 'sort_order'],
        'Factor': ['id (PK)', 'decision_id (FK)', 'name', 'category', 'weight', 'description'],
        'FactorScore': ['id (PK)', 'factor_id (FK)', 'option_id (FK)', 'score INT', 'notes'],
        'Result': ['id (PK)', 'decision_id (FK)', 'recommended_id', 'confidence', 'explanation'],
        'FactorTemplate': ['id (PK)', 'name', 'category', 'default_weight', 'is_active'],
        'Feedback': ['id (PK)', 'user_id (FK)', 'type', 'title', 'message', 'status'],
        'AIParameter': ['id (PK)', 'key', 'value', 'value_type', 'description'],
    }
    
    box_w, box_h = 230, 200
    
    for name, config in entity_configs.items():
        x, y = config['x'], config['y']
        color, bg = config['color'], config['bg']
        
        # Shadow
        draw_rounded_rectangle(draw, [x+4, y+4, x+box_w+4, y+box_h+4], 12, fill='#CBD5E1')
        
        # Main box
        draw_rounded_rectangle(draw, [x, y, x+box_w, y+box_h], 12, fill=bg, outline=color, width=2)
        
        # Header
        draw_rounded_rectangle(draw, [x, y, x+box_w, y+40], 12, fill=color)
        draw.rectangle([x, y+20, x+box_w, y+40], fill=color)
        
        # Entity name
        draw.text((x + 15, y + 10), name, fill='#FFFFFF', font=fonts['heading'])
        
        # Attributes
        attrs = entities_data.get(name, [])
        for i, attr in enumerate(attrs[:7]):
            attr_color = '#1E40AF' if 'PK' in attr else ('#7C3AED' if 'FK' in attr else '#374151')
            draw.text((x + 15, y + 50 + i * 20), attr, fill=attr_color, font=fonts['small'])
    
    # Relationships with better styling
    relationships = [
        ('User', 'UserSettings', '1:1', '#3B82F6'),
        ('User', 'ActivityLog', '1:N', '#3B82F6'),
        ('User', 'Decision', '1:N', '#10B981'),
        ('User', 'Feedback', '1:N', '#A855F7'),
        ('Decision', 'DecisionOption', '1:N', '#F59E0B'),
        ('Decision', 'Factor', '1:N', '#EF4444'),
        ('Decision', 'Result', '1:1', '#84CC16'),
        ('Factor', 'FactorScore', '1:N', '#06B6D4'),
        ('DecisionOption', 'FactorScore', '1:N', '#06B6D4'),
    ]
    
    for e1_name, e2_name, rel, color in relationships:
        e1, e2 = entity_configs[e1_name], entity_configs[e2_name]
        
        if abs(e1['y'] - e2['y']) > 200:
            x1, y1 = e1['x'] + box_w//2, e1['y'] + box_h
            x2, y2 = e2['x'] + box_w//2, e2['y']
        else:
            x1, y1 = e1['x'] + box_w, e1['y'] + box_h//2
            x2, y2 = e2['x'], e2['y'] + box_h//2
        
        draw_arrow(draw, (x1, y1), (x2, y2), color, width=2)
        
        mid_x, mid_y = (x1 + x2)//2, (y1 + y2)//2
        # Relationship label with background
        draw_rounded_rectangle(draw, [mid_x-20, mid_y-12, mid_x+20, mid_y+12], 6, fill='#FFFFFF', outline=color)
        draw.text((mid_x-12, mid_y-8), rel, fill=color, font=fonts['small'])
    
    # Legend
    draw_rounded_rectangle(draw, [1200, 120, 1750, 320], 15, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((1220, 135), "Legend", fill='#1F2937', font=fonts['subtitle'])
    
    legend_items = [
        ('Primary Key (PK)', '#1E40AF'),
        ('Foreign Key (FK)', '#7C3AED'),
        ('1:1 Relationship', '#3B82F6'),
        ('1:N Relationship', '#10B981'),
    ]
    for i, (text, color) in enumerate(legend_items):
        draw.ellipse([1230, 180 + i*30, 1250, 200 + i*30], fill=color)
        draw.text((1260, 180 + i*30), text, fill='#374151', font=fonts['body'])
    
    output_path = os.path.join(PNG_DIR, 'ERD_Diagram.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_architecture_png():
    """Create enhanced system architecture diagram as PNG"""
    print("Creating Architecture diagram PNG...")
    
    width, height = 1600, 1000
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#4F46E5'), hex_to_rgb('#7C3AED'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 180, 25), "System Architecture Overview", fill='#FFFFFF', font=fonts['title'])
    
    # Layer configurations
    layers = [
        {'name': 'PRESENTATION LAYER', 'y': 100, 'color': '#3B82F6', 'bg': '#DBEAFE',
         'items': [('Flutter Mobile App', '#2563EB'), ('REST API Client', '#1D4ED8'), 
                   ('JWT Auth Handler', '#1E40AF'), ('State Management', '#1E3A8A')]},
        {'name': 'API LAYER (Django REST Framework)', 'y': 250, 'color': '#10B981', 'bg': '#D1FAE5',
         'items': [('URL Routing', '#059669'), ('ViewSets', '#047857'), 
                   ('Serializers', '#065F46'), ('Permissions', '#064E3B')]},
        {'name': 'BUSINESS LOGIC LAYER', 'y': 400, 'color': '#F59E0B', 'bg': '#FEF3C7',
         'items': [('AI Analysis Engine', '#D97706'), ('Decision Service', '#B45309'), 
                   ('Auth Service', '#92400E'), ('Analytics Engine', '#78350F')]},
        {'name': 'DATA ACCESS LAYER', 'y': 550, 'color': '#EF4444', 'bg': '#FEE2E2',
         'items': [('Django ORM', '#DC2626'), ('Model Managers', '#B91C1C'), 
                   ('QuerySets', '#991B1B'), ('Migrations', '#7F1D1D')]},
    ]
    
    layer_h = 120
    
    for layer in layers:
        y = layer['y']
        
        # Layer background with shadow
        draw_rounded_rectangle(draw, [54, y+4, width-46, y+layer_h+4], 15, fill='#CBD5E1')
        draw_rounded_rectangle(draw, [50, y, width-50, y+layer_h], 15, fill=layer['bg'], outline=layer['color'], width=3)
        
        # Layer title
        draw.text((80, y+10), layer['name'], fill=layer['color'], font=fonts['subtitle'])
        
        # Items
        item_w = 280
        start_x = 100
        for i, (item_name, item_color) in enumerate(layer['items']):
            x = start_x + i * (item_w + 30)
            draw_rounded_rectangle(draw, [x, y+50, x+item_w, y+100], 10, fill='#FFFFFF', outline=item_color, width=2)
            draw.text((x+20, y+65), item_name, fill=item_color, font=fonts['body'])
        
        # Arrow to next layer
        if y < 500:
            arrow_y = y + layer_h + 15
            draw_arrow(draw, (width//2, arrow_y), (width//2, arrow_y + 30), '#64748B', width=3, arrow_size=12)
    
    # Database at bottom
    db_y = 700
    draw_rounded_rectangle(draw, [width//2-154, db_y+4, width//2+154, db_y+104], 20, fill='#CBD5E1')
    draw_rounded_rectangle(draw, [width//2-150, db_y, width//2+150, db_y+100], 20, fill='#312E81', outline='#4338CA', width=3)
    draw.text((width//2-70, db_y+15), "DATABASE", fill='#FFFFFF', font=fonts['subtitle'])
    draw.text((width//2-80, db_y+50), "PostgreSQL / SQLite", fill='#C7D2FE', font=fonts['body'])
    
    # Database cylinder effect
    draw.ellipse([width//2-150, db_y-10, width//2+150, db_y+20], fill='#4338CA')
    draw.text((width//2-70, db_y-2), "DATABASE", fill='#FFFFFF', font=fonts['subtitle'])
    
    # Arrow to database
    draw_arrow(draw, (width//2, 670), (width//2, db_y-15), '#64748B', width=3, arrow_size=12)
    
    # Side panel - Technologies
    draw_rounded_rectangle(draw, [1300, 100, 1550, 450], 15, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((1320, 115), "Technologies", fill='#1F2937', font=fonts['subtitle'])
    
    techs = ['Python 3.10+', 'Django 4.2', 'DRF 3.14', 'Flutter 3.x', 'Dart', 'SQLite/PostgreSQL', 'JWT Auth', 'REST API']
    for i, tech in enumerate(techs):
        draw.ellipse([1320, 160 + i*32, 1335, 175 + i*32], fill='#10B981')
        draw.text((1345, 158 + i*32), tech, fill='#374151', font=fonts['body'])
    
    output_path = os.path.join(PNG_DIR, 'Architecture_Diagram.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_auth_flow_png():
    """Create enhanced authentication flow diagram as PNG"""
    print("Creating Auth Flow diagram PNG...")
    
    width, height = 1400, 950
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#059669'), hex_to_rgb('#10B981'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 180, 25), "JWT Authentication Flow", fill='#FFFFFF', font=fonts['title'])
    
    # Actors with enhanced styling
    actors = [
        ('Client App', 180, '#3B82F6', '#DBEAFE'),
        ('Auth API', 460, '#10B981', '#D1FAE5'),
        ('JWT Service', 740, '#8B5CF6', '#EDE9FE'),
        ('Database', 1020, '#F59E0B', '#FEF3C7'),
    ]
    
    for name, x, color, bg in actors:
        # Actor box with shadow
        draw_rounded_rectangle(draw, [x-64, 104, x+64, 164], 10, fill='#94A3B8')
        draw_rounded_rectangle(draw, [x-70, 100, x+70, 160], 10, fill=bg, outline=color, width=3)
        draw.text((x-50, 120), name, fill=color, font=fonts['body'])
        # Lifeline
        draw.line([x, 160, x, 900], fill='#CBD5E1', width=2)
    
    # Section dividers
    draw_rounded_rectangle(draw, [50, 180, 1350, 530], 15, fill='#ECFDF5', outline='#10B981', width=2)
    draw.text((70, 190), "LOGIN FLOW", fill='#059669', font=fonts['subtitle'])
    
    draw_rounded_rectangle(draw, [50, 550, 1350, 880], 15, fill='#EFF6FF', outline='#3B82F6', width=2)
    draw.text((70, 560), "AUTHENTICATED REQUEST FLOW", fill='#2563EB', font=fonts['subtitle'])
    
    # Login flow steps
    login_steps = [
        (180, 460, 230, 'POST /auth/login', '#10B981', '{email, password}'),
        (460, 740, 270, 'Validate credentials', '#8B5CF6', ''),
        (740, 1020, 310, 'Query user by email', '#F59E0B', ''),
        (1020, 740, 350, 'Return user data', '#F59E0B', ''),
        (740, 460, 390, 'Generate JWT tokens', '#8B5CF6', ''),
        (460, 180, 430, 'Return tokens', '#10B981', '{access, refresh}'),
    ]
    
    for x1, x2, y, label, color, note in login_steps:
        draw_arrow(draw, (x1, y), (x2, y), color, width=3)
        mid_x = (x1 + x2) // 2
        # Label background
        label_w = len(label) * 7 + 20
        draw_rounded_rectangle(draw, [mid_x - label_w//2, y-22, mid_x + label_w//2, y-2], 5, fill='#FFFFFF', outline=color)
        draw.text((mid_x - label_w//2 + 10, y-18), label, fill=color, font=fonts['small'])
        if note:
            draw.text((mid_x - 30, y+5), note, fill='#6B7280', font=fonts['tiny'])
    
    # Authenticated request flow
    auth_steps = [
        (180, 460, 600, 'Request + Bearer token', '#3B82F6', ''),
        (460, 740, 640, 'Verify JWT signature', '#8B5CF6', ''),
        (740, 460, 680, 'Token valid + user_id', '#8B5CF6', ''),
        (460, 1020, 720, 'Fetch protected data', '#F59E0B', ''),
        (1020, 460, 760, 'Return data', '#F59E0B', ''),
        (460, 180, 800, 'JSON Response', '#3B82F6', '{success, data}'),
    ]
    
    for x1, x2, y, label, color, note in auth_steps:
        draw_arrow(draw, (x1, y), (x2, y), color, width=3)
        mid_x = (x1 + x2) // 2
        label_w = len(label) * 7 + 20
        draw_rounded_rectangle(draw, [mid_x - label_w//2, y-22, mid_x + label_w//2, y-2], 5, fill='#FFFFFF', outline=color)
        draw.text((mid_x - label_w//2 + 10, y-18), label, fill=color, font=fonts['small'])
        if note:
            draw.text((mid_x - 30, y+5), note, fill='#6B7280', font=fonts['tiny'])
    
    # JWT Token info box
    draw_rounded_rectangle(draw, [1100, 180, 1340, 400], 12, fill='#FFFFFF', outline='#8B5CF6', width=2)
    draw.text((1120, 195), "JWT Token Structure", fill='#7C3AED', font=fonts['heading'])
    
    jwt_info = [
        "Access Token (5 min):",
        "  - user_id: UUID",
        "  - token_type: access",
        "  - exp: timestamp",
        "",
        "Refresh Token (24h):",
        "  - user_id: UUID",
        "  - token_type: refresh",
        "  - jti: unique_id",
    ]
    for i, line in enumerate(jwt_info):
        color = '#7C3AED' if ':' in line and not line.startswith(' ') else '#4B5563'
        draw.text((1115, 225 + i*18), line, fill=color, font=fonts['small'])
    
    output_path = os.path.join(PNG_DIR, 'Auth_Flow_Diagram.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_decision_flow_png():
    """Create enhanced decision flow diagram as PNG"""
    print("Creating Decision Flow diagram PNG...")
    
    width, height = 1600, 800
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#F59E0B'), hex_to_rgb('#EF4444'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 180, 25), "Decision Creation Flow", fill='#FFFFFF', font=fonts['title'])
    
    # Steps with enhanced styling
    steps = [
        ('1', 'Enter Title &\nDescription', 80, '#3B82F6', '#DBEAFE', 'Define your decision'),
        ('2', 'Add\nOptions', 320, '#10B981', '#D1FAE5', '2+ choices needed'),
        ('3', 'Add\nFactors', 560, '#F59E0B', '#FEF3C7', 'PRO & CON factors'),
        ('4', 'Rate\nFactors', 800, '#EF4444', '#FEE2E2', 'Score 1-10'),
        ('5', 'AI\nAnalysis', 1040, '#8B5CF6', '#EDE9FE', 'Weighted scoring'),
        ('6', 'View\nResult', 1280, '#06B6D4', '#CFFAFE', 'Best recommendation'),
    ]
    
    box_w, box_h = 180, 100
    
    for num, label, x, color, bg, desc in steps:
        y = 150
        
        # Shadow
        draw_rounded_rectangle(draw, [x+4, y+4, x+box_w+4, y+box_h+4], 15, fill='#CBD5E1')
        
        # Main box
        draw_rounded_rectangle(draw, [x, y, x+box_w, y+box_h], 15, fill=bg, outline=color, width=3)
        
        # Step number circle
        draw.ellipse([x+box_w//2-20, y-25, x+box_w//2+20, y+15], fill=color)
        draw.text((x+box_w//2-8, y-15), num, fill='#FFFFFF', font=fonts['heading'])
        
        # Label
        lines = label.split('\n')
        for i, line in enumerate(lines):
            text_w = len(line) * 8
            draw.text((x + box_w//2 - text_w//2, y + 25 + i*22), line, fill=color, font=fonts['heading'])
        
        # Description
        draw.text((x + 15, y + box_h + 10), desc, fill='#6B7280', font=fonts['small'])
        
        # Arrow to next
        if x < 1200:
            draw_arrow(draw, (x + box_w + 10, y + box_h//2), (x + box_w + 50, y + box_h//2), '#94A3B8', width=3)
    
    # State machine section
    draw_rounded_rectangle(draw, [50, 350, 1550, 750], 20, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((80, 370), "Decision State Machine", fill='#1F2937', font=fonts['subtitle'])
    
    # States
    states = [
        ('DRAFT', 200, 480, '#FEF3C7', '#F59E0B', 'Initial state after creation'),
        ('ANALYZED', 650, 480, '#D1FAE5', '#10B981', 'AI analysis completed'),
        ('ARCHIVED', 1100, 480, '#F3F4F6', '#6B7280', 'Decision archived'),
    ]
    
    state_w, state_h = 180, 80
    
    for name, x, y, bg, color, desc in states:
        # State box
        draw_rounded_rectangle(draw, [x+3, y+3, x+state_w+3, y+state_h+3], 20, fill='#CBD5E1')
        draw_rounded_rectangle(draw, [x, y, x+state_w, y+state_h], 20, fill=bg, outline=color, width=3)
        draw.text((x + state_w//2 - 35, y + 25), name, fill=color, font=fonts['heading'])
        draw.text((x + 20, y + state_h + 15), desc, fill='#6B7280', font=fonts['small'])
    
    # Transitions
    draw_arrow(draw, (380, 520), (650, 520), '#10B981', width=3)
    draw_rounded_rectangle(draw, [470, 490, 570, 520], 8, fill='#FFFFFF', outline='#10B981')
    draw.text((485, 495), "analyze()", fill='#10B981', font=fonts['small'])
    
    draw_arrow(draw, (830, 520), (1100, 520), '#6B7280', width=3)
    draw_rounded_rectangle(draw, [920, 490, 1020, 520], 8, fill='#FFFFFF', outline='#6B7280')
    draw.text((935, 495), "archive()", fill='#6B7280', font=fonts['small'])
    
    # Re-analyze loop
    draw.arc([600, 400, 800, 480], 180, 360, fill='#F59E0B', width=3)
    draw_arrow(draw, (700, 405), (700, 420), '#F59E0B', width=2, arrow_size=8)
    draw.text((670, 380), "re-analyze", fill='#F59E0B', font=fonts['small'])
    
    # Legend
    draw_rounded_rectangle(draw, [1300, 400, 1530, 600], 12, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((1320, 415), "Legend", fill='#1F2937', font=fonts['heading'])
    
    legend_items = [
        ('Draft', '#F59E0B'),
        ('Analyzed', '#10B981'),
        ('Archived', '#6B7280'),
        ('Transition', '#3B82F6'),
    ]
    for i, (text, color) in enumerate(legend_items):
        draw.ellipse([1320, 455 + i*35, 1340, 475 + i*35], fill=color)
        draw.text((1350, 455 + i*35), text, fill='#374151', font=fonts['body'])
    
    output_path = os.path.join(PNG_DIR, 'Decision_Flow_Diagram.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_ai_analysis_flow_png():
    """Create enhanced AI Analysis flow diagram as PNG"""
    print("Creating AI Analysis Flow diagram PNG...")
    
    width, height = 1600, 1000
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#8B5CF6'), hex_to_rgb('#EC4899'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 150, 25), "AI Analysis Flow", fill='#FFFFFF', font=fonts['title'])
    
    # Process steps (left side)
    steps = [
        ('1', 'Client Request', '#3B82F6', 'POST /decisions/{id}/ai/analyze'),
        ('2', 'Load Data', '#10B981', 'Get options, factors, scores'),
        ('3', 'Calculate Scores', '#F59E0B', 'Apply weighted scoring'),
        ('4', 'Normalize', '#EF4444', 'Scale to 0-100 range'),
        ('5', 'Confidence', '#8B5CF6', 'Variance & completeness'),
        ('6', 'Generate Result', '#06B6D4', 'Build recommendation'),
    ]
    
    box_w, box_h = 250, 60
    start_y = 120
    
    for i, (num, label, color, desc) in enumerate(steps):
        y = start_y + i * 100
        x = 80
        
        # Shadow
        draw_rounded_rectangle(draw, [x+3, y+3, x+box_w+3, y+box_h+3], 12, fill='#CBD5E1')
        
        # Box with gradient-like effect
        draw_rounded_rectangle(draw, [x, y, x+box_w, y+box_h], 12, fill='#FFFFFF', outline=color, width=3)
        
        # Step number
        draw.ellipse([x-25, y+box_h//2-20, x+15, y+box_h//2+20], fill=color)
        draw.text((x-12, y+box_h//2-10), num, fill='#FFFFFF', font=fonts['heading'])
        
        # Label and description
        draw.text((x+25, y+12), label, fill=color, font=fonts['heading'])
        draw.text((x+25, y+35), desc, fill='#6B7280', font=fonts['small'])
        
        # Arrow to next
        if i < len(steps) - 1:
            draw_arrow(draw, (x+box_w//2, y+box_h+10), (x+box_w//2, y+box_h+40), '#94A3B8', width=2)
    
    # Algorithm panel (right side)
    draw_rounded_rectangle(draw, [400, 120, 1550, 550], 20, fill='#FFFFFF', outline='#8B5CF6', width=3)
    draw.text((430, 140), "AI Scoring Algorithm", fill='#7C3AED', font=fonts['subtitle'])
    
    # Algorithm pseudo-code with syntax highlighting
    algo_lines = [
        ("FOR EACH", " option ", "IN", " options:", '#8B5CF6', '#1F2937', '#8B5CF6', '#1F2937'),
        ("    weighted_score = ", "0", "", "", '#1F2937', '#EF4444', '', ''),
        ("", "", "", "", '', '', '', ''),
        ("    FOR EACH", " factor ", "IN", " factors:", '#8B5CF6', '#1F2937', '#8B5CF6', '#1F2937'),
        ("        score = ", "factor_scores[factor, option]", " or ", "5", '#1F2937', '#10B981', '#1F2937', '#EF4444'),
        ("        weighted = ", "score * factor.weight", "", "", '#1F2937', '#F59E0B', '', ''),
        ("", "", "", "", '', '', '', ''),
        ("        IF", " factor.category == 'PRO'", ":", "", '#8B5CF6', '#10B981', '#1F2937', ''),
        ("            weighted_score ", "+= weighted", "", "", '#1F2937', '#10B981', '', ''),
        ("        ELIF", " factor.category == 'CON'", ":", "", '#8B5CF6', '#EF4444', '#1F2937', ''),
        ("            weighted_score ", "-= weighted", "", "", '#1F2937', '#EF4444', '', ''),
    ]
    
    for i, parts in enumerate(algo_lines):
        y_pos = 185 + i * 24
        x_pos = 450
        for j in range(0, len(parts), 2):
            if parts[j]:
                draw.text((x_pos, y_pos), parts[j], fill=parts[j+1], font=fonts['body'])
                x_pos += len(parts[j]) * 8
    
    # Normalization formula box
    draw_rounded_rectangle(draw, [430, 460, 850, 530], 12, fill='#FEF3C7', outline='#F59E0B', width=2)
    draw.text((450, 475), "Normalization:", fill='#B45309', font=fonts['heading'])
    draw.text((450, 500), "normalized = ((raw - min) / range) × 100", fill='#1F2937', font=fonts['body'])
    
    # Confidence formula box
    draw_rounded_rectangle(draw, [880, 460, 1520, 530], 12, fill='#EDE9FE', outline='#8B5CF6', width=2)
    draw.text((900, 475), "Confidence Calculation:", fill='#7C3AED', font=fonts['heading'])
    draw.text((900, 500), "confidence = CLAMP(variance×0.6 + completeness×0.4, 30, 95)", fill='#1F2937', font=fonts['small'])
    
    # Result structure panel
    draw_rounded_rectangle(draw, [400, 580, 1550, 950], 20, fill='#FFFFFF', outline='#10B981', width=3)
    draw.text((430, 600), "Analysis Result Structure", fill='#059669', font=fonts['subtitle'])
    
    result_fields = [
        ('decision_id', 'UUID', 'Reference to analyzed decision'),
        ('recommended_option', 'Object', 'Best scoring option details'),
        ('confidence_level', 'Integer (30-95)', 'Algorithm confidence percentage'),
        ('explanation', 'String', 'Human-readable recommendation'),
        ('breakdown', 'Array', 'Per-option scores and factors'),
        ('analysis_version', 'String', 'Algorithm version used'),
    ]
    
    for i, (field, type_val, desc) in enumerate(result_fields):
        y_pos = 650 + i * 45
        draw_rounded_rectangle(draw, [450, y_pos, 1500, y_pos+38], 8, fill='#ECFDF5', outline='#10B981')
        draw.text((470, y_pos+8), field, fill='#059669', font=fonts['heading'])
        draw.text((700, y_pos+10), type_val, fill='#6B7280', font=fonts['body'])
        draw.text((920, y_pos+10), desc, fill='#374151', font=fonts['body'])
    
    output_path = os.path.join(PNG_DIR, 'AI_Analysis_Flow.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_user_journey_png():
    """Create enhanced user journey diagram as PNG"""
    print("Creating User Journey diagram PNG...")
    
    width, height = 1700, 1100
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#06B6D4'), hex_to_rgb('#3B82F6'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 150, 25), "User Journey Flow", fill='#FFFFFF', font=fonts['title'])
    
    # New User Entry section
    draw_rounded_rectangle(draw, [50, 100, 380, 280], 20, fill='#DBEAFE', outline='#3B82F6', width=3)
    draw.text((70, 115), "NEW USER", fill='#1E40AF', font=fonts['subtitle'])
    
    # Onboarding circle
    draw.ellipse([100, 160, 200, 230], fill='#FFFFFF', outline='#3B82F6', width=2)
    draw.text((115, 185), "Onboarding", fill='#3B82F6', font=fonts['small'])
    
    # Register / Guest options
    draw_rounded_rectangle(draw, [230, 150, 360, 195], 10, fill='#D1FAE5', outline='#10B981', width=2)
    draw.text((255, 162), "Register", fill='#059669', font=fonts['body'])
    
    draw_rounded_rectangle(draw, [230, 210, 360, 255], 10, fill='#FEF3C7', outline='#F59E0B', width=2)
    draw.text((260, 222), "Guest", fill='#B45309', font=fonts['body'])
    
    # Arrows
    draw_arrow(draw, (200, 185), (230, 170), '#10B981', width=2)
    draw_arrow(draw, (200, 205), (230, 230), '#F59E0B', width=2)
    
    # Main Dashboard section
    draw_rounded_rectangle(draw, [420, 100, 1650, 300], 20, fill='#ECFDF5', outline='#10B981', width=3)
    draw.text((450, 115), "DASHBOARD", fill='#059669', font=fonts['subtitle'])
    
    dashboard_items = [
        ('Create Decision', 480, 160, '#DBEAFE', '#3B82F6'),
        ('View Journal', 720, 160, '#D1FAE5', '#10B981'),
        ('Profile', 960, 160, '#FEF3C7', '#F59E0B'),
        ('Admin Panel', 1200, 160, '#EDE9FE', '#8B5CF6'),
    ]
    
    for label, x, y, bg, color in dashboard_items:
        draw_rounded_rectangle(draw, [x+3, y+3, x+193, y+73], 12, fill='#CBD5E1')
        draw_rounded_rectangle(draw, [x, y, x+190, y+70], 12, fill=bg, outline=color, width=2)
        draw.text((x+30, y+22), label, fill=color, font=fonts['heading'])
    
    # Arrow from new user to dashboard
    draw_arrow(draw, (380, 190), (420, 190), '#64748B', width=3)
    
    # Decision Flow section
    draw_rounded_rectangle(draw, [50, 330, 1650, 580], 20, fill='#FEF3C7', outline='#F59E0B', width=3)
    draw.text((80, 350), "DECISION CREATION FLOW", fill='#B45309', font=fonts['subtitle'])
    
    decision_steps = [
        ('Step 1', 'Enter Title', 100, '#DBEAFE', '#3B82F6'),
        ('Step 2', 'Add Options', 330, '#D1FAE5', '#10B981'),
        ('Step 3', 'Add Factors', 560, '#FEF3C7', '#F59E0B'),
        ('Step 4', 'Rate (1-10)', 790, '#FEE2E2', '#EF4444'),
        ('Step 5', 'AI Analysis', 1020, '#EDE9FE', '#8B5CF6'),
        ('Step 6', 'Result', 1250, '#CFFAFE', '#06B6D4'),
    ]
    
    for step, label, x, bg, color in decision_steps:
        y = 400
        draw_rounded_rectangle(draw, [x+3, y+3, x+183, y+103], 15, fill='#CBD5E1')
        draw_rounded_rectangle(draw, [x, y, x+180, y+100], 15, fill=bg, outline=color, width=2)
        
        # Step badge
        draw.ellipse([x+70, y-15, x+110, y+25], fill=color)
        draw.text((x+82, y-5), step[-1], fill='#FFFFFF', font=fonts['heading'])
        
        draw.text((x+40, y+45), label, fill=color, font=fonts['heading'])
        
        if x < 1200:
            draw_arrow(draw, (x+180, y+50), (x+230, y+50), '#94A3B8', width=2)
    
    # Recommendation box
    draw_rounded_rectangle(draw, [1450, 380, 1620, 560], 15, fill='#FFFFFF', outline='#06B6D4', width=3)
    draw.text((1470, 400), "Recommendation", fill='#0891B2', font=fonts['heading'])
    rec_items = ['Best Option', 'Confidence %', 'Explanation', 'Breakdown']
    for i, item in enumerate(rec_items):
        draw.ellipse([1470, 435 + i*28, 1485, 450 + i*28], fill='#06B6D4')
        draw.text((1495, 432 + i*28), item, fill='#374151', font=fonts['small'])
    
    # Journal Flow section
    draw_rounded_rectangle(draw, [50, 620, 700, 820], 20, fill='#FCE7F3', outline='#EC4899', width=3)
    draw.text((80, 640), "JOURNAL FLOW", fill='#BE185D', font=fonts['subtitle'])
    
    journal_steps = [
        ('View Past\nDecisions', 100, 690, '#FDF2F8', '#EC4899'),
        ('Rate\nSatisfaction', 300, 690, '#FAF5FF', '#A855F7'),
        ('Add\nNotes', 500, 690, '#FEF3C7', '#F59E0B'),
    ]
    
    for label, x, y, bg, color in journal_steps:
        draw_rounded_rectangle(draw, [x, y, x+150, y+80], 12, fill=bg, outline=color, width=2)
        lines = label.split('\n')
        for i, line in enumerate(lines):
            draw.text((x+25, y+15+i*25), line, fill=color, font=fonts['body'])
        
        if x < 500:
            draw_arrow(draw, (x+150, y+40), (x+200, y+40), '#94A3B8', width=2)
    
    # Admin Flow section
    draw_rounded_rectangle(draw, [750, 620, 1650, 820], 20, fill='#E0E7FF', outline='#6366F1', width=3)
    draw.text((780, 640), "ADMIN FLOW", fill='#4338CA', font=fonts['subtitle'])
    
    admin_steps = [
        ('Dashboard', 800, 690, '#EDE9FE', '#8B5CF6'),
        ('Analytics', 1000, 690, '#DBEAFE', '#3B82F6'),
        ('Users', 1200, 690, '#D1FAE5', '#10B981'),
        ('Config', 1400, 690, '#FEF3C7', '#F59E0B'),
    ]
    
    for label, x, y, bg, color in admin_steps:
        draw_rounded_rectangle(draw, [x, y, x+150, y+80], 12, fill=bg, outline=color, width=2)
        draw.text((x+35, y+28), label, fill=color, font=fonts['heading'])
        
        if x < 1400:
            draw_arrow(draw, (x+150, y+40), (x+200, y+40), '#94A3B8', width=2)
    
    # Connections between sections
    draw.line([555, 230, 555, 330], fill='#F59E0B', width=3)
    draw.polygon([(555, 330), (550, 320), (560, 320)], fill='#F59E0B')
    
    draw.line([370, 530, 370, 620], fill='#EC4899', width=3)
    draw.polygon([(370, 620), (365, 610), (375, 610)], fill='#EC4899')
    
    draw.line([1200, 230, 1200, 620], fill='#6366F1', width=2)
    draw.polygon([(1200, 620), (1195, 610), (1205, 610)], fill='#6366F1')
    
    # Legend
    draw_rounded_rectangle(draw, [50, 860, 500, 1050], 15, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((70, 875), "User Types & Flow Legend", fill='#1F2937', font=fonts['heading'])
    
    legend_items = [
        ('New User Path', '#3B82F6'),
        ('Decision Flow', '#F59E0B'),
        ('Journal Flow', '#EC4899'),
        ('Admin Flow', '#6366F1'),
    ]
    for i, (text, color) in enumerate(legend_items):
        draw.ellipse([80, 920 + i*30, 100, 940 + i*30], fill=color)
        draw.text((115, 918 + i*30), text, fill='#374151', font=fonts['body'])
    
    output_path = os.path.join(PNG_DIR, 'User_Journey_Flow.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_data_flow_png():
    """Create enhanced data flow diagram as PNG"""
    print("Creating Data Flow diagram PNG...")
    
    width, height = 1600, 1000
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#10B981'), hex_to_rgb('#06B6D4'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 150, 25), "Data Flow Diagram", fill='#FFFFFF', font=fonts['title'])
    
    # External Entities with enhanced styling
    entities = [
        ('USER', 80, 250, '#3B82F6', '#DBEAFE'),
        ('ADMIN', 80, 700, '#10B981', '#D1FAE5'),
    ]
    
    for label, x, y, color, bg in entities:
        draw_rounded_rectangle(draw, [x+4, y+4, x+154, y+104], 15, fill='#CBD5E1')
        draw_rounded_rectangle(draw, [x, y, x+150, y+100], 15, fill=bg, outline=color, width=3)
        draw.text((x+40, y+35), label, fill=color, font=fonts['subtitle'])
    
    # Processes (circles with gradient effect)
    processes = [
        ('1.0', 'AUTH', 320, 150, '#F59E0B', '#FEF3C7'),
        ('2.0', 'DECISION', 550, 280, '#8B5CF6', '#EDE9FE'),
        ('3.0', 'AI ANALYSIS', 780, 400, '#EF4444', '#FEE2E2'),
        ('4.0', 'FEEDBACK', 320, 550, '#EC4899', '#FCE7F3'),
        ('5.0', 'ANALYTICS', 550, 700, '#06B6D4', '#CFFAFE'),
    ]
    
    for num, name, x, y, color, bg in processes:
        # Circle
        draw.ellipse([x+3, y+3, x+133, y+133], fill='#CBD5E1')
        draw.ellipse([x, y, x+130, y+130], fill=bg, outline=color, width=3)
        draw.text((x+45, y+35), num, fill=color, font=fonts['heading'])
        draw.text((x+20, y+60), name, fill=color, font=fonts['body'])
    
    # Data Stores with enhanced styling
    stores = [
        ('D1: USER_STORE', 1100, 120, ['users', 'settings', 'activity'], '#8B5CF6'),
        ('D2: DECISION_STORE', 1100, 280, ['decisions', 'options'], '#F59E0B'),
        ('D3: FACTOR_STORE', 1100, 440, ['factors', 'scores'], '#EF4444'),
        ('D4: RESULT_STORE', 1100, 600, ['results', 'ai_params'], '#10B981'),
        ('D5: FEEDBACK_STORE', 1100, 760, ['feedback'], '#EC4899'),
    ]
    
    for label, x, y, items, color in stores:
        # Data store shape
        draw_rounded_rectangle(draw, [x, y, x+300, y+100], 0, fill='#FFFFFF', outline=color, width=2)
        draw.line([x, y+30, x+300, y+30], fill=color, width=2)
        draw.text((x+10, y+5), label, fill=color, font=fonts['heading'])
        for i, item in enumerate(items):
            draw.ellipse([x+15, y+42+i*20, x+25, y+52+i*20], fill=color)
            draw.text((x+35, y+40+i*20), item, fill='#374151', font=fonts['small'])
    
    # Data flows with enhanced arrows
    flows = [
        ((230, 300), (320, 200), 'Credentials', '#F59E0B'),
        ((450, 200), (1100, 160), 'User Data', '#8B5CF6'),
        ((230, 320), (550, 330), 'Decision', '#8B5CF6'),
        ((680, 340), (1100, 320), 'Save', '#F59E0B'),
        ((680, 380), (780, 450), 'Analyze', '#EF4444'),
        ((910, 450), (1100, 480), 'Scores', '#EF4444'),
        ((910, 500), (1100, 640), 'Results', '#10B981'),
        ((230, 350), (320, 550), 'Feedback', '#EC4899'),
        ((450, 600), (1100, 800), 'Save', '#EC4899'),
        ((230, 750), (550, 750), 'Query', '#06B6D4'),
        ((680, 750), (1100, 640), 'Analytics', '#06B6D4'),
    ]
    
    for (x1, y1), (x2, y2), label, color in flows:
        draw_arrow(draw, (x1, y1), (x2, y2), color, width=2)
        mid_x, mid_y = (x1+x2)//2, (y1+y2)//2
        draw_rounded_rectangle(draw, [mid_x-35, mid_y-12, mid_x+35, mid_y+12], 6, fill='#FFFFFF', outline=color)
        draw.text((mid_x-30, mid_y-8), label, fill=color, font=fonts['small'])
    
    # Legend
    draw_rounded_rectangle(draw, [1100, 880, 1550, 980], 15, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((1120, 895), "Legend", fill='#1F2937', font=fonts['heading'])
    
    legend_items = [
        ('External Entity', '#3B82F6', 'rect'),
        ('Process', '#F59E0B', 'circle'),
        ('Data Store', '#8B5CF6', 'rect'),
        ('Data Flow', '#10B981', 'arrow'),
    ]
    for i, (text, color, shape) in enumerate(legend_items):
        x_pos = 1130 + (i % 2) * 200
        y_pos = 930 + (i // 2) * 25
        if shape == 'circle':
            draw.ellipse([x_pos, y_pos, x_pos+15, y_pos+15], fill=color)
        elif shape == 'arrow':
            draw.line([x_pos, y_pos+7, x_pos+15, y_pos+7], fill=color, width=2)
        else:
            draw.rectangle([x_pos, y_pos, x_pos+15, y_pos+15], fill=color)
        draw.text((x_pos+25, y_pos), text, fill='#374151', font=fonts['small'])
    
    output_path = os.path.join(PNG_DIR, 'Data_Flow_Diagram.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_api_request_flow_png():
    """Create enhanced API request flow diagram as PNG"""
    print("Creating API Request Flow diagram PNG...")
    
    width, height = 1600, 1000
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#EF4444'), hex_to_rgb('#F59E0B'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 150, 25), "API Request Flow", fill='#FFFFFF', font=fonts['title'])
    
    # Client
    draw_rounded_rectangle(draw, [54, 124, 204, 204], 15, fill='#CBD5E1')
    draw_rounded_rectangle(draw, [50, 120, 200, 200], 15, fill='#DBEAFE', outline='#3B82F6', width=3)
    draw.text((75, 150), "Flutter App", fill='#1E40AF', font=fonts['heading'])
    
    # Middleware Stack
    draw_rounded_rectangle(draw, [250, 100, 950, 220], 20, fill='#FFFFFF', outline='#64748B', width=2)
    draw.text((280, 115), "DJANGO MIDDLEWARE STACK", fill='#475569', font=fonts['subtitle'])
    
    middleware = [
        ('CORS', '#D1FAE5', '#10B981'),
        ('Session', '#FEF3C7', '#F59E0B'),
        ('Auth', '#FCE7F3', '#EC4899'),
        ('Exception', '#CFFAFE', '#06B6D4'),
    ]
    
    for i, (name, bg, color) in enumerate(middleware):
        x = 280 + i * 160
        draw_rounded_rectangle(draw, [x, 155, x+130, 200], 10, fill=bg, outline=color, width=2)
        draw.text((x+30, 167), name, fill=color, font=fonts['body'])
        if i < 3:
            draw_arrow(draw, (x+130, 177), (x+160, 177), '#94A3B8', width=2, arrow_size=8)
    
    # JWT Validation
    draw_rounded_rectangle(draw, [1000, 110, 1300, 210], 15, fill='#EDE9FE', outline='#8B5CF6', width=3)
    draw.text((1020, 125), "JWT VALIDATION", fill='#7C3AED', font=fonts['heading'])
    jwt_steps = ['Extract token', 'Verify signature', 'Check expiry', 'Load user']
    for i, step in enumerate(jwt_steps):
        draw.ellipse([1025, 155 + i*12, 1035, 165 + i*12], fill='#8B5CF6')
        draw.text((1045, 152 + i*12), step, fill='#4B5563', font=fonts['tiny'])
    
    # Arrow to JWT
    draw_arrow(draw, (870, 177), (1000, 160), '#8B5CF6', width=2)
    
    # URL Router
    draw_rounded_rectangle(draw, [250, 250, 950, 400], 20, fill='#D1FAE5', outline='#10B981', width=3)
    draw.text((280, 270), "URL ROUTER", fill='#059669', font=fonts['subtitle'])
    
    routes = [
        ('/api/v1/auth/*', 'Core URLs', '#3B82F6'),
        ('/api/v1/decisions/*', 'Decision URLs', '#F59E0B'),
        ('/api/v1/feedback/*', 'Feedback URLs', '#EC4899'),
        ('/api/v1/admin/*', 'Admin URLs', '#8B5CF6'),
    ]
    for i, (route, target, color) in enumerate(routes):
        y = 310 + i * 22
        draw.text((300, y), route, fill='#374151', font=fonts['body'])
        draw_arrow(draw, (520, y+8), (580, y+8), color, width=2, arrow_size=6)
        draw.text((590, y), target, fill=color, font=fonts['body'])
    
    # View/ViewSet section
    draw_rounded_rectangle(draw, [250, 430, 1550, 780], 20, fill='#FEF3C7', outline='#F59E0B', width=3)
    draw.text((280, 450), "VIEW / VIEWSET", fill='#B45309', font=fonts['subtitle'])
    
    # Permission Check
    draw_rounded_rectangle(draw, [280, 500, 650, 580], 12, fill='#FEE2E2', outline='#EF4444', width=2)
    draw.text((300, 515), "PERMISSION CHECK", fill='#DC2626', font=fonts['heading'])
    draw.text((300, 545), "IsAuthenticated → IsAdmin → IsOwner", fill='#4B5563', font=fonts['small'])
    
    # Request Validation
    draw_rounded_rectangle(draw, [700, 500, 1100, 580], 12, fill='#D1FAE5', outline='#10B981', width=2)
    draw.text((720, 515), "REQUEST VALIDATION", fill='#059669', font=fonts['heading'])
    draw.text((720, 545), "Serializer → validate() → create/update()", fill='#4B5563', font=fonts['small'])
    
    # Business Logic
    draw_rounded_rectangle(draw, [280, 610, 650, 690], 12, fill='#DBEAFE', outline='#3B82F6', width=2)
    draw.text((300, 625), "BUSINESS LOGIC", fill='#1E40AF', font=fonts['heading'])
    draw.text((300, 655), "Views → Services → Models → DB", fill='#4B5563', font=fonts['small'])
    
    # Response Format
    draw_rounded_rectangle(draw, [700, 610, 1100, 760], 12, fill='#FCE7F3', outline='#EC4899', width=2)
    draw.text((720, 625), "RESPONSE FORMAT", fill='#BE185D', font=fonts['heading'])
    response_lines = ['{ "success": true/false,', '  "message": "...",', '  "data": {...},', '  "error": {...} }']
    for i, line in enumerate(response_lines):
        draw.text((730, 660 + i*22), line, fill='#4B5563', font=fonts['small'])
    
    # Database
    draw_rounded_rectangle(draw, [1200, 500, 1500, 650], 20, fill='#312E81', outline='#4338CA', width=3)
    draw.ellipse([1200, 485, 1500, 530], fill='#4338CA')
    draw.text((1300, 495), "DATABASE", fill='#FFFFFF', font=fonts['heading'])
    draw.text((1270, 560), "PostgreSQL / SQLite", fill='#C7D2FE', font=fonts['body'])
    
    # Response
    draw_rounded_rectangle(draw, [54, 854, 204, 934], 15, fill='#CBD5E1')
    draw_rounded_rectangle(draw, [50, 850, 200, 930], 15, fill='#D1FAE5', outline='#10B981', width=3)
    draw.text((65, 875), "JSON Response", fill='#059669', font=fonts['body'])
    
    # Flow arrows
    draw_arrow(draw, (200, 160), (250, 160), '#3B82F6', width=3)
    draw.text((210, 135), "HTTP + JWT", fill='#3B82F6', font=fonts['small'])
    
    draw_arrow(draw, (600, 220), (600, 250), '#64748B', width=2)
    draw_arrow(draw, (600, 400), (600, 430), '#64748B', width=2)
    draw_arrow(draw, (1100, 540), (1200, 560), '#4338CA', width=2)
    draw_arrow(draw, (700, 750), (125, 850), '#10B981', width=3)
    
    output_path = os.path.join(PNG_DIR, 'API_Request_Flow.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_admin_operations_png():
    """Create enhanced admin operations flow diagram as PNG"""
    print("Creating Admin Operations diagram PNG...")
    
    width, height = 1600, 900
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#8B5CF6'), hex_to_rgb('#EC4899'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 180, 25), "Admin Operations Flow", fill='#FFFFFF', font=fonts['title'])
    
    # Admin Dashboard Hub
    draw_rounded_rectangle(draw, [604, 104, 1004, 184], 20, fill='#CBD5E1')
    draw_rounded_rectangle(draw, [600, 100, 1000, 180], 20, fill='#DBEAFE', outline='#3B82F6', width=3)
    draw.text((700, 115), "ADMIN DASHBOARD", fill='#1E40AF', font=fonts['subtitle'])
    draw.text((660, 145), "Overview | Stats | Quick Actions", fill='#3B82F6', font=fonts['body'])
    
    # Four main operation sections
    sections = [
        ('Usage Analytics', 80, 230, '#10B981', '#D1FAE5', [
            'GET /admin/analytics/usage',
            '• total_users',
            '• active_users', 
            '• total_decisions',
            '• avg_confidence',
        ]),
        ('Feedback Analytics', 420, 230, '#F59E0B', '#FEF3C7', [
            'GET /admin/analytics/feedback',
            '• total_feedback',
            '• by_type',
            '• by_status',
            '• response_rate',
        ]),
        ('Factor Templates', 760, 230, '#EC4899', '#FCE7F3', [
            'CRUD /admin/templates/',
            '• name',
            '• category (PRO/CON)',
            '• default_weight',
            '• is_active',
        ]),
        ('AI Parameters', 1100, 230, '#8B5CF6', '#EDE9FE', [
            'GET/PATCH /admin/ai-params/',
            '• min_confidence: 30',
            '• max_confidence: 95',
            '• weight_factor: 1.5',
            '• default_weight: 5',
        ]),
    ]
    
    box_w, box_h = 300, 220
    
    for name, x, y, color, bg, items in sections:
        draw_rounded_rectangle(draw, [x+4, y+4, x+box_w+4, y+box_h+4], 15, fill='#CBD5E1')
        draw_rounded_rectangle(draw, [x, y, x+box_w, y+box_h], 15, fill=bg, outline=color, width=3)
        draw.text((x+20, y+20), name, fill=color, font=fonts['heading'])
        
        for i, item in enumerate(items):
            text_color = color if i == 0 else '#374151'
            font_type = 'body' if i == 0 else 'small'
            draw.text((x+25, y+55+i*30), item, fill=text_color, font=fonts[font_type])
        
        # Arrow from dashboard
        center_x = x + box_w // 2
        draw_arrow(draw, (800, 180), (center_x, y), color, width=2)
    
    # User Management section
    draw_rounded_rectangle(draw, [84, 504, 684, 724], 20, fill='#CBD5E1')
    draw_rounded_rectangle(draw, [80, 500, 680, 720], 20, fill='#CFFAFE', outline='#06B6D4', width=3)
    draw.text((100, 520), "USER MANAGEMENT", fill='#0891B2', font=fonts['subtitle'])
    
    user_ops = [
        ('List Users', 120, 580, '#A5F3FC'),
        ('View Activity', 300, 580, '#67E8F9'),
        ('Manage Roles', 480, 580, '#22D3EE'),
    ]
    
    for name, x, y, color in user_ops:
        draw_rounded_rectangle(draw, [x, y, x+150, y+60], 12, fill=color, outline='#0891B2', width=2)
        draw.text((x+25, y+18), name, fill='#0E7490', font=fonts['body'])
    
    draw.text((110, 670), "GET /admin/users/ | GET /admin/logs/", fill='#0891B2', font=fonts['body'])
    
    # Activity Logs section
    draw_rounded_rectangle(draw, [784, 504, 1384, 724], 20, fill='#CBD5E1')
    draw_rounded_rectangle(draw, [780, 500, 1380, 720], 20, fill='#FEE2E2', outline='#EF4444', width=3)
    draw.text((800, 520), "ACTIVITY LOGS & AUDIT", fill='#DC2626', font=fonts['subtitle'])
    
    log_items = [
        ('Login/Logout events', '#22C55E'),
        ('Decision created/analyzed', '#3B82F6'),
        ('Admin actions logged', '#F59E0B'),
        ('IP & timestamp tracking', '#8B5CF6'),
    ]
    for i, (item, color) in enumerate(log_items):
        draw.ellipse([820, 580+i*30, 835, 595+i*30], fill=color)
        draw.text((850, 578+i*30), item, fill='#374151', font=fonts['body'])
    
    draw.text((810, 690), "Filterable by: user, action, date range", fill='#6B7280', font=fonts['small'])
    
    # Connection lines from upper sections
    draw_arrow(draw, (380, 450), (380, 500), '#06B6D4', width=2)
    draw_arrow(draw, (1080, 450), (1080, 500), '#EF4444', width=2)
    
    # Legend
    draw_rounded_rectangle(draw, [80, 780, 600, 880], 15, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((100, 795), "Admin Capabilities", fill='#1F2937', font=fonts['heading'])
    capabilities = [
        ('View Analytics', '#10B981'),
        ('Manage Templates', '#EC4899'),
        ('Configure AI', '#8B5CF6'),
        ('Audit Logs', '#EF4444'),
    ]
    for i, (cap, color) in enumerate(capabilities):
        x_pos = 120 + (i % 2) * 220
        y_pos = 830 + (i // 2) * 25
        draw.ellipse([x_pos, y_pos, x_pos+15, y_pos+15], fill=color)
        draw.text((x_pos+25, y_pos-2), cap, fill='#374151', font=fonts['small'])
    
    output_path = os.path.join(PNG_DIR, 'Admin_Operations_Flow.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def create_api_endpoints_png():
    """Create enhanced API endpoints overview diagram"""
    print("Creating API Endpoints diagram PNG...")
    
    width, height = 1600, 1000
    img = Image.new('RGB', (width, height), '#F8FAFC')
    draw = ImageDraw.Draw(img)
    fonts = get_fonts()
    
    # Gradient header
    draw_gradient_header(img, 0, 80, hex_to_rgb('#3B82F6'), hex_to_rgb('#8B5CF6'))
    draw = ImageDraw.Draw(img)
    
    # Title
    draw.text((width//2 - 120, 25), "API Endpoints", fill='#FFFFFF', font=fonts['title'])
    
    # HTTP Method colors
    method_colors = {
        'GET': '#22C55E',
        'POST': '#3B82F6', 
        'PUT': '#F59E0B',
        'PATCH': '#F59E0B',
        'DELETE': '#EF4444',
    }
    
    # Endpoint groups with enhanced styling
    groups = [
        {
            'name': 'Authentication',
            'color': '#3B82F6',
            'bg': '#DBEAFE',
            'x': 50, 'y': 100,
            'endpoints': [
                ('POST', '/auth/register'),
                ('POST', '/auth/login'),
                ('POST', '/auth/logout'),
                ('POST', '/auth/guest-login'),
                ('POST', '/auth/convert-guest'),
                ('POST', '/token/refresh'),
            ]
        },
        {
            'name': 'Users',
            'color': '#10B981',
            'bg': '#D1FAE5',
            'x': 420, 'y': 100,
            'endpoints': [
                ('GET', '/users/me'),
                ('PUT', '/users/me'),
                ('PATCH', '/users/me'),
                ('GET', '/users/settings'),
                ('PUT', '/users/settings'),
                ('GET', '/users/activity'),
            ]
        },
        {
            'name': 'Decisions',
            'color': '#F59E0B',
            'bg': '#FEF3C7',
            'x': 790, 'y': 100,
            'endpoints': [
                ('GET', '/decisions/'),
                ('POST', '/decisions/'),
                ('GET', '/decisions/{id}/'),
                ('PUT', '/decisions/{id}/'),
                ('DELETE', '/decisions/{id}/'),
                ('POST', '/decisions/{id}/ai/analyze'),
                ('GET', '/decisions/{id}/ai/suggest'),
            ]
        },
        {
            'name': 'Options & Factors',
            'color': '#EC4899',
            'bg': '#FCE7F3',
            'x': 1200, 'y': 100,
            'endpoints': [
                ('GET', '/.../options/'),
                ('POST', '/.../options/'),
                ('GET', '/.../factors/'),
                ('POST', '/.../factors/'),
                ('POST', '/.../factors/{id}/scores/'),
            ]
        },
        {
            'name': 'Journal & Templates',
            'color': '#8B5CF6',
            'bg': '#EDE9FE',
            'x': 50, 'y': 420,
            'endpoints': [
                ('GET', '/journal/'),
                ('GET', '/templates/'),
            ]
        },
        {
            'name': 'Feedback',
            'color': '#06B6D4',
            'bg': '#CFFAFE',
            'x': 420, 'y': 420,
            'endpoints': [
                ('GET', '/feedback/'),
                ('POST', '/feedback/'),
                ('GET', '/feedback/{id}/'),
                ('PATCH', '/feedback/{id}/'),
                ('DELETE', '/feedback/{id}/'),
            ]
        },
        {
            'name': 'Admin Analytics',
            'color': '#EF4444',
            'bg': '#FEE2E2',
            'x': 790, 'y': 420,
            'endpoints': [
                ('GET', '/admin/analytics/usage'),
                ('GET', '/admin/analytics/feedback'),
                ('GET', '/admin/users/'),
                ('GET', '/admin/logs/'),
            ]
        },
        {
            'name': 'Admin Config',
            'color': '#64748B',
            'bg': '#F1F5F9',
            'x': 1200, 'y': 420,
            'endpoints': [
                ('GET', '/admin/templates/'),
                ('POST', '/admin/templates/'),
                ('PUT', '/admin/templates/{id}/'),
                ('DELETE', '/admin/templates/{id}/'),
                ('GET', '/admin/ai-parameters/'),
                ('PATCH', '/admin/ai-parameters/{key}/'),
            ]
        },
    ]
    
    box_w, box_h = 340, 280
    
    for group in groups:
        x, y = group['x'], group['y']
        color = group['color']
        bg = group['bg']
        
        # Shadow
        draw_rounded_rectangle(draw, [x+4, y+4, x+box_w+4, y+box_h+4], 15, fill='#CBD5E1')
        
        # Main box
        draw_rounded_rectangle(draw, [x, y, x+box_w, y+box_h], 15, fill=bg, outline=color, width=3)
        
        # Header bar
        draw_rounded_rectangle(draw, [x, y, x+box_w, y+40], 15, fill=color)
        # Fix bottom corners of header
        draw.rectangle([x, y+25, x+box_w, y+40], fill=color)
        draw.text((x+15, y+10), group['name'], fill='#FFFFFF', font=fonts['heading'])
        
        # Endpoints
        for i, (method, endpoint) in enumerate(group['endpoints']):
            y_pos = y + 55 + i * 28
            method_color = method_colors.get(method, '#6B7280')
            
            # Method badge
            badge_w = 50
            draw_rounded_rectangle(draw, [x+15, y_pos, x+15+badge_w, y_pos+20], 5, fill=method_color)
            draw.text((x+20, y_pos+3), method, fill='#FFFFFF', font=fonts['tiny'])
            
            # Endpoint path
            draw.text((x+75, y_pos+2), endpoint, fill='#374151', font=fonts['small'])
    
    # Legend
    draw_rounded_rectangle(draw, [50, 750, 600, 850], 15, fill='#FFFFFF', outline='#E5E7EB', width=2)
    draw.text((70, 770), "HTTP Methods", fill='#1F2937', font=fonts['heading'])
    
    methods = [
        ('GET', '#22C55E', 'Retrieve data'),
        ('POST', '#3B82F6', 'Create new'),
        ('PUT/PATCH', '#F59E0B', 'Update'),
        ('DELETE', '#EF4444', 'Remove'),
    ]
    for i, (method, color, desc) in enumerate(methods):
        x_pos = 90 + (i % 2) * 250
        y_pos = 805 + (i // 2) * 25
        draw_rounded_rectangle(draw, [x_pos, y_pos, x_pos+60, y_pos+20], 5, fill=color)
        draw.text((x_pos+10, y_pos+3), method, fill='#FFFFFF', font=fonts['tiny'])
        draw.text((x_pos+70, y_pos+2), desc, fill='#6B7280', font=fonts['small'])
    
    # Base URL note
    draw_rounded_rectangle(draw, [650, 750, 1550, 850], 15, fill='#FEF3C7', outline='#F59E0B', width=2)
    draw.text((670, 770), "Base URL: /api/v1/", fill='#B45309', font=fonts['heading'])
    draw.text((670, 805), "All endpoints require JWT authentication except:", fill='#78350F', font=fonts['body'])
    draw.text((670, 830), "/auth/register, /auth/login, /auth/guest-login", fill='#92400E', font=fonts['small'])
    
    output_path = os.path.join(PNG_DIR, 'API_Endpoints_Diagram.png')
    img.save(output_path, quality=95)
    print(f"  Created: {output_path}")


def main():
    """Main function to generate all documentation"""
    print("=" * 60)
    print("Decision Companion - Documentation Generator")
    print("=" * 60)
    print()
    
    # Convert MD files to PDF
    md_files = [
        'API_DOCUMENTATION.md',
        'DATABASE_DIAGRAMS.md',
        'FLOW_DIAGRAMS.md',
        'BACKEND_GUIDE.md',
    ]
    
    print("Generating PDF files...")
    print("-" * 40)
    for md_file in md_files:
        md_path = os.path.join(DOCS_DIR, md_file)
        if os.path.exists(md_path):
            pdf_name = md_file.replace('.md', '.pdf')
            pdf_path = os.path.join(PDF_DIR, pdf_name)
            try:
                convert_md_to_pdf(md_path, pdf_path)
            except Exception as e:
                print(f"  Error converting {md_file}: {e}")
    
    print()
    print("Generating PNG diagrams...")
    print("-" * 40)
    
    try:
        create_erd_png()
    except Exception as e:
        print(f"  Error creating ERD: {e}")
    
    try:
        create_architecture_png()
    except Exception as e:
        print(f"  Error creating Architecture diagram: {e}")
    
    try:
        create_auth_flow_png()
    except Exception as e:
        print(f"  Error creating Auth Flow diagram: {e}")
    
    try:
        create_decision_flow_png()
    except Exception as e:
        print(f"  Error creating Decision Flow diagram: {e}")
    
    try:
        create_ai_analysis_flow_png()
    except Exception as e:
        print(f"  Error creating AI Analysis Flow diagram: {e}")
    
    try:
        create_user_journey_png()
    except Exception as e:
        print(f"  Error creating User Journey diagram: {e}")
    
    try:
        create_data_flow_png()
    except Exception as e:
        print(f"  Error creating Data Flow diagram: {e}")
    
    try:
        create_api_request_flow_png()
    except Exception as e:
        print(f"  Error creating API Request Flow diagram: {e}")
    
    try:
        create_admin_operations_png()
    except Exception as e:
        print(f"  Error creating Admin Operations diagram: {e}")
    
    try:
        create_api_endpoints_png()
    except Exception as e:
        print(f"  Error creating API Endpoints diagram: {e}")
    
    print()
    print("=" * 60)
    print("Documentation generation complete!")
    print(f"PDF files: {PDF_DIR}")
    print(f"PNG files: {PNG_DIR}")
    print("=" * 60)


if __name__ == '__main__':
    main()
