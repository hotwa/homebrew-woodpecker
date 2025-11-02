#!/bin/bash
# GitHub Actions 配置检查脚本

set -e

echo "🔍 检查 GitHub Actions 配置..."
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查结果数组
PASSED=0
FAILED=0
WARNINGS=0

check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description: ${BLUE}$file${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description: ${BLUE}$file${NC} ${RED}(缺失)${NC}"
        ((FAILED++))
        return 1
    fi
}

check_yaml_syntax() {
    local file=$1
    
    if command -v ruby >/dev/null 2>&1; then
        if ruby -ryaml -e "YAML.load_file('$file')" >/dev/null 2>&1; then
            return 0
        else
            echo -e "${RED}✗${NC} YAML 语法错误: ${BLUE}$file${NC}"
            ((FAILED++))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} 无法检查 YAML 语法（ruby 未安装）"
        ((WARNINGS++))
        return 0
    fi
}

check_formula_syntax() {
    local file=$1
    
    if command -v ruby >/dev/null 2>&1; then
        if ruby -c "$file" >/dev/null 2>&1; then
            return 0
        else
            echo -e "${RED}✗${NC} Ruby 语法错误: ${BLUE}$file${NC}"
            ((FAILED++))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} 无法检查 Ruby 语法（ruby 未安装）"
        ((WARNINGS++))
        return 0
    fi
}

# 1. 检查必需的 workflow 文件
echo "1️⃣  检查 Workflow 文件"
echo "─────────────────────────────"
check_file ".github/workflows/auto-update.yml" "自动更新工作流"
check_file ".github/workflows/test-formula.yml" "测试构建工作流"
echo ""

# 2. 检查文档文件
echo "2️⃣  检查文档文件"
echo "─────────────────────────────"
check_file ".github/AUTOMATION.md" "自动化文档"
check_file ".github/QUICKSTART.md" "快速开始指南"
check_file "README.md" "主文档"
echo ""

# 3. 检查 Formula 文件
echo "3️⃣  检查 Formula 文件"
echo "─────────────────────────────"
check_file "Formula/woodpecker-agent.rb" "Agent Formula"
check_file "Formula/woodpecker-cli.rb" "CLI Formula"
check_file "Formula/woodpecker-plugin-git.rb" "Git Plugin Formula"
check_file "Formula/woodpecker-plugin-s3.rb" "S3 Plugin Formula"
check_file "Formula/woodpecker-plugin-docker-buildx.rb" "Docker Buildx Plugin Formula"
echo ""

# 4. 检查 YAML 语法
echo "4️⃣  检查 YAML 语法"
echo "─────────────────────────────"
if [ -f ".github/workflows/auto-update.yml" ]; then
    if check_yaml_syntax ".github/workflows/auto-update.yml"; then
        echo -e "${GREEN}✓${NC} auto-update.yml 语法正确"
        ((PASSED++))
    fi
fi

if [ -f ".github/workflows/test-formula.yml" ]; then
    if check_yaml_syntax ".github/workflows/test-formula.yml"; then
        echo -e "${GREEN}✓${NC} test-formula.yml 语法正确"
        ((PASSED++))
    fi
fi
echo ""

# 5. 检查 Formula 语法
echo "5️⃣  检查 Formula Ruby 语法"
echo "─────────────────────────────"
for formula in Formula/*.rb; do
    if [ -f "$formula" ]; then
        if check_formula_syntax "$formula"; then
            echo -e "${GREEN}✓${NC} $(basename $formula) 语法正确"
            ((PASSED++))
        fi
    fi
done
echo ""

# 6. 检查 Git 状态
echo "6️⃣  检查 Git 状态"
echo "─────────────────────────────"
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Git 仓库检测成功"
    ((PASSED++))
    
    # 检查远程仓库
    if git remote -v | grep -q "github.com"; then
        REMOTE_URL=$(git remote get-url origin)
        echo -e "${GREEN}✓${NC} GitHub 远程仓库: ${BLUE}$REMOTE_URL${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} 未检测到 GitHub 远程仓库"
        ((WARNINGS++))
    fi
    
    # 检查未提交的更改
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠${NC} 存在未提交的更改"
        ((WARNINGS++))
        echo -e "   ${YELLOW}提示：记得提交并推送这些文件${NC}"
    else
        echo -e "${GREEN}✓${NC} 工作目录干净"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗${NC} 不是 Git 仓库"
    ((FAILED++))
fi
echo ""

# 7. 检查当前版本信息
echo "7️⃣  当前版本信息"
echo "─────────────────────────────"
if [ -f "Formula/woodpecker-agent.rb" ]; then
    AGENT_VERSION=$(grep -E '^\s+tag:\s+' Formula/woodpecker-agent.rb | sed -E 's/.*"(.*)".*/\1/' || echo "未找到")
    AGENT_REVISION=$(grep -E '^\s+revision\s+' Formula/woodpecker-agent.rb | sed -E 's/.*revision\s+([0-9]+).*/\1/' || echo "0")
    echo -e "${BLUE}woodpecker-agent:${NC} $AGENT_VERSION (revision $AGENT_REVISION)"
fi

if [ -f "Formula/woodpecker-cli.rb" ]; then
    CLI_VERSION=$(grep -E '^\s+version\s+' Formula/woodpecker-cli.rb | sed -E 's/.*"(.*)".*/\1/' || echo "未找到")
    CLI_COMMIT=$(grep -E '^\s+revision:\s+' Formula/woodpecker-cli.rb | sed -E 's/.*"(.*)".*/\1/' || echo "未找到")
    echo -e "${BLUE}woodpecker-cli:${NC} $CLI_VERSION (commit ${CLI_COMMIT:0:8})"
fi
echo ""

# 8. 检查上游最新版本
echo "8️⃣  检查上游最新版本"
echo "─────────────────────────────"
if command -v curl >/dev/null 2>&1; then
    LATEST_TAG=$(curl -s https://api.github.com/repos/woodpecker-ci/woodpecker/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")
    
    if [ -n "$LATEST_TAG" ]; then
        echo -e "${BLUE}上游最新版本:${NC} $LATEST_TAG"
        
        if [ -f "Formula/woodpecker-agent.rb" ]; then
            if [ "$AGENT_VERSION" == "$LATEST_TAG" ]; then
                echo -e "${GREEN}✓${NC} 本地版本已是最新"
                ((PASSED++))
            else
                echo -e "${YELLOW}⚠${NC} 有新版本可更新: $AGENT_VERSION → $LATEST_TAG"
                ((WARNINGS++))
            fi
        fi
    else
        echo -e "${YELLOW}⚠${NC} 无法获取上游版本信息（可能是网络问题）"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} curl 未安装，无法检查上游版本"
    ((WARNINGS++))
fi
echo ""

# 9. GitHub Actions 权限提示
echo "9️⃣  GitHub 仓库配置提示"
echo "─────────────────────────────"
echo -e "${BLUE}请确保在 GitHub 仓库设置中：${NC}"
echo "1. Settings → Actions → General"
echo "2. Workflow permissions 设置为: ${GREEN}Read and write permissions${NC}"
echo "3. 勾选: ${GREEN}Allow GitHub Actions to create and approve pull requests${NC}"
echo ""
echo -e "${YELLOW}💡 提示：${NC}如果首次使用，访问 Actions 页面启用 workflows"
echo ""

# 总结
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 检查结果摘要"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ 通过: $PASSED${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ 警告: $WARNINGS${NC}"
fi
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}✗ 失败: $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 配置检查完成！可以提交并推送到 GitHub 了。${NC}"
    echo ""
    echo "下一步："
    echo "  git add .github/ README.md"
    echo "  git commit -m 'feat: 添加 GitHub Actions 自动更新功能'"
    echo "  git push origin main"
    echo ""
    echo "然后访问 GitHub Actions 页面启用 workflows"
    exit 0
else
    echo -e "${RED}❌ 发现 $FAILED 个错误，请修复后重试。${NC}"
    exit 1
fi

